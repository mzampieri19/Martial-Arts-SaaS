import express from 'express';
import cors from 'cors';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Supabase client (you'll need to set these as environment variables)
const supabaseUrl = process.env.SUPABASE_URL || 'https://nopgyqscrjjkyapwcqwf.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'your-service-role-key';
const supabase: SupabaseClient = createClient(supabaseUrl, supabaseKey);

// Auth routes
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    // Get user role
    const { data: profile } = await supabase
      .from('profiles')
      .select('Role')
      .eq('id', data.user.id)
      .single();

    res.json({
      user: data.user,
      role: profile?.Role || 'STUDENT',
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/api/auth/signup', async (req, res) => {
  try {
    const { email, password, username, avatar } = req.body;
    
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) throw error;

    // Create profile
    await supabase
      .from('profiles')
      .upsert({
        id: data.user?.id,
        username,
      });

    // Handle avatar upload if provided
    if (avatar && data.user) {
      // Avatar upload logic here
    }

    res.json({ user: data.user });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Classes routes
app.get('/api/classes', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('classes')
      .select('*')
      .order('date', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.get('/api/classes/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('classes')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/api/classes', async (req, res) => {
  try {
    const classData = req.body;
    
    const { data, error } = await supabase
      .from('classes')
      .insert(classData)
      .select('id')
      .single();

    if (error) throw error;

    // Link goal if provided
    if (classData.goal_id) {
      await supabase
        .from('class_goal_links')
        .insert({
          class_id: data.id,
          goal_id: classData.goal_id,
        });
    }

    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.put('/api/classes/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('classes')
      .update(req.body)
      .eq('id', req.params.id)
      .select();

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.delete('/api/classes/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('classes')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;
    res.json({ success: true });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Student classes routes
app.get('/api/student-classes', async (req, res) => {
  try {
    const userId = req.query.user_id as string;
    
    const { data, error } = await supabase
      .from('student_classes')
      .select('*, classes(id, class_name, date, time, coach_assigned)')
      .eq('profile_id', userId);

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/api/student-classes', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('student_classes')
      .insert(req.body);

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Goals routes
app.get('/api/goals', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('goals')
      .select('*')
      .order('title');

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.get('/api/class-goal-links/:classId', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('class_goal_links')
      .select('goal_id, goals(id, key, title, required_sessions, advancement)')
      .eq('class_id', req.params.classId);

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Profile routes
app.get('/api/profiles/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.put('/api/profiles/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .update(req.body)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// User progress routes
app.get('/api/user-progress/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Get goal progress
    const { data: goalProgress } = await supabase
      .from('user_goal_completions')
      .select('goal_id, progress, advancement')
      .eq('user_id', userId);

    // Get attendance counts
    const { data: attendance } = await supabase
      .rpc('get_user_attendance_counts', { p_user_id: userId });

    // Get marks
    const { data: marks } = await supabase
      .from('user_goal_class_marks')
      .select('goal_id, class_id')
      .eq('user_id', userId);

    res.json({
      goalProgress,
      attendance,
      marks,
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/api/toggle-mark', async (req, res) => {
  try {
    const { userId, goalId, classId, mark } = req.body;
    
    const { data, error } = await supabase
      .rpc('toggle_user_goal_mark', {
        p_user_id: userId,
        p_goal_id: goalId,
        p_class_id: classId,
        p_mark: mark,
      });

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Coaches route
app.get('/api/coaches', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('username, Role')
      .ilike('Role', 'coach');

    if (error) throw error;
    res.json(data);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
