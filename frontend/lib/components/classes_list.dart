// This is a reusable widget that is used to display a list of classes in the frontend.
// Should be a slidable action to register/unregister for students, edit class details for coaches and owners.
// The widget takes in a list of classes and displays them in a ListView.
// Different class lists will be passed to this widget based on the user role and the context (e.g., all classes, my classes, registered classes).

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../constants/app_constants.dart';

/// Different visual styles for the classes list.
enum ClassListType { compact, card, detailed }

class ClassesList extends StatelessWidget {
  final List<dynamic> classes;
  final Function(dynamic) onRegister;
  final Function(dynamic) onUnregister;
  final Function(dynamic) onEdit;
  // When false, action buttons (register/unregister/edit) will be hidden.
  final bool enableActions;
  // Choose how each class row is displayed.
  final ClassListType classListType;
  // When true the internal list will NOT scroll and will be shrinkWrapped.
  // Set to false to enable internal scrolling (useful when placed in a
  // fixed-height parent like `Expanded`). Default true preserves previous behavior.
  final bool disableInnerScroll;
  // When true, each row will support a slide action (Register) if actions are enabled.
  final bool enableSlidable;
  // Optional tap handler when a class row is tapped.
  final Function(dynamic)? onTap;
  // Optional map of already-marked goals keyed by '$goalId:$classId' -> true
  final Map<String, bool>? marksCache;
  // Callback invoked when a goal checkbox is toggled from within the card.
  // Signature: (goalId, classId, mark)
  final Function(int goalId, int classId, bool mark)? onToggleGoal;

  ClassesList({
    required this.classes,
    required this.onRegister,
    required this.onUnregister,
    required this.onEdit,
    required this.enableActions,
    this.classListType = ClassListType.card,
    this.disableInnerScroll = true,
    this.enableSlidable = true,
    required this.onTap,
    this.marksCache,
    this.onToggleGoal,
    Key? key,
  }) : super(key: key);

  String _getTitle(dynamic item) {
    if (item == null) return '(no title)';
    // If the backend returned a wrapper (e.g. student_classes with nested
    // `classes` row), unwrap it.
    if (item is Map) {
      final data = (item['classes'] is Map) ? item['classes'] as Map : item;
      final title = (data['class_name'] ?? data['name'] ?? data['title'] ?? '')
          .toString();
      return title.isNotEmpty ? title : '(no title)';
    }
    // Fallback for objects with a `name` or `class_name` property
    try {
      final val = item.class_name ?? item.name ?? item.title;
      return val?.toString() ?? item.toString();
    } catch (e) {
      return item.toString();
    }
  }

  String _getSubtitle(dynamic item) {
    if (item == null) return '';
    if (item is Map) {
      final data = (item['classes'] is Map) ? item['classes'] as Map : item;
      return (data['coach_assigned'] ?? data['instructor'] ?? data['description'] ?? '')
          .toString();
    }
    try {
      final val = item.coach_assigned ?? item.instructor ?? item.description;
      return val?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildActions(dynamic classItem) {
    if (!enableActions) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => onEdit(classItem),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => onRegister(classItem),
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => onUnregister(classItem),
        ),
      ],
    );
  }

  Widget _buildCompactItem(BuildContext context, dynamic classItem) {
    return ListTile(
      title: Text(_getTitle(classItem)),
      subtitle: _getSubtitle(classItem).isNotEmpty
          ? Text(_getSubtitle(classItem))
          : null,
      trailing: enableActions ? _buildActions(classItem) : null,
    );
  }

  Widget _buildCardItem(BuildContext context, dynamic classItem) {
    final subtitle = _getSubtitle(classItem);
    // unwrap nested row if present
  final data = (classItem is Map && classItem['classes'] is Map)
    ? classItem['classes'] as Map
    : (classItem is Map ? classItem : {});

  // leading color (either provided, or fallback by difficulty/type)
  Color leadingColor = AppConstants.accentColor;
    try {
      final c = data['color'];
      if (c is int) leadingColor = Color(c);
      else if (c is Color) leadingColor = c;
      else if (c is String) {
        // try parse hex string
        final cleaned = c.replaceAll('#', '');
        leadingColor = Color(int.parse('0xFF$cleaned'));
      }
    } catch (e) {
      leadingColor = AppConstants.accentColor;
    }

    final difficulty = (data['difficulty'] ?? '').toString();
    Color badgeColor = AppConstants.accentColorLight;
    if (difficulty.toLowerCase().contains('beginner')) {
      badgeColor = AppConstants.accentColorLight;
    } else if (difficulty.toLowerCase().contains('advanced')) {
      badgeColor = AppConstants.infoColor.withOpacity(0.15);
    } else if (difficulty.toLowerCase().contains('intermediate')) {
      badgeColor = Colors.red.shade100;
    }

    return StatefulBuilder(builder: (context, setState) {
      bool expanded = false;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppConstants.spaceMd / 2),
        child: Material(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          elevation: AppConstants.elevationSm,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            onTap: () {
              try {
                // toggle inline expansion so tapping the whole card opens goals
                setState(() {
                  expanded = !expanded;
                });
                if (onTap != null) onTap!(classItem);
              } catch (_) {}
            },
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // colored indicator (wider and taller for emphasis)
                Container(
                  width: 10,
                  height: 72,
                  decoration: BoxDecoration(
                    color: leadingColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: leadingColor.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _getTitle(classItem),
                              style: AppConstants.headingSm.copyWith(
                                color: AppConstants.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (difficulty.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusLg),
                              ),
                              child: Text(
                                difficulty,
                                style: AppConstants.labelXs.copyWith(
                                    color: AppConstants.textPrimary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (subtitle.isNotEmpty)
                        Text('with coach $subtitle',
                            style: AppConstants.bodyMd
                                .copyWith(color: AppConstants.textPrimary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: AppConstants.iconLg,
                              color: AppConstants.textPrimary.withOpacity(0.85)),
                          const SizedBox(width: 6),
                          Text(
                            '${data['date'] ?? ''} ${data['time'] ?? ''}'.trim(),
                            style: AppConstants.bodySm
                                .copyWith(color: AppConstants.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.sports_martial_arts_rounded,
                              size: AppConstants.iconXl,
                              color: AppConstants.textPrimary.withOpacity(0.9)),
                          const SizedBox(width: 8),
                          Text(
                            // Resolve numeric class type IDs to friendly names if possible
                            MartialArtsConstants.resolveClassType(
                                data['type_of_class'] ?? data['class_type'] ?? data['type'] ?? ''),
                            style: AppConstants.bodySm
                                .copyWith(color: AppConstants.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Builder(builder: (ctx) {
                        final goals = (data['goals'] is List)
                            ? List.from(data['goals'] as List)
                            : (classItem is Map && classItem['goals'] is List)
                                ? List.from(classItem['goals'] as List)
                                : <dynamic>[];
                        if (goals.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  expanded = !expanded;
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Goals (${goals.length})', style: AppConstants.labelSm.copyWith(color: AppConstants.textSecondary)),
                                  Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppConstants.textSecondary),
                                ],
                              ),
                            ),
                            if (expanded) ...[
                              const SizedBox(height: 8),
                              Column(
                                children: goals.map<Widget>((g) {
                                  final goalId = (g is Map) ? (g['id'] as int? ?? 0) : 0;
                                  final cid = (data['id'] ?? data['class_id'] ?? (data['classes'] is Map ? data['classes']['id'] : null)) is int
                                      ? (data['id'] ?? data['class_id'] ?? (data['classes'] is Map ? data['classes']['id'] : null)) as int
                                      : (classItem is Map ? (classItem['id'] ?? classItem['class_id']) as int? ?? 0 : 0);
                                  final keyStr = '$goalId:$cid';
                                  var checked = marksCache != null ? (marksCache![keyStr] ?? false) : false;
                                  return Row(
                                    children: [
                                      Expanded(child: Text(g['title'] ?? g['key'] ?? 'Goal ${goalId}', style: AppConstants.bodyMd)),
                                      Checkbox(
                                        value: checked,
                                        onChanged: (v) async {
                                          final mark = v == true;
                                          // optimistically update local view
                                          checked = mark;
                                          setState(() {});
                                          try {
                                            if (onToggleGoal != null) await onToggleGoal!(goalId, cid, mark);
                                          } catch (_) {}
                                        },
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ]
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
    }
  );
  }

  Widget _buildDetailedItem(BuildContext context, dynamic classItem) {
    final subtitle = _getSubtitle(classItem);
    String date = '';
    String time = '';
    String difficulty = '';
    if (classItem is Map) {
      date = (classItem['date'] ?? '').toString();
      time = (classItem['time'] ?? '').toString();
      difficulty = (classItem['difficulty'] ?? classItem['level'] ?? '').toString();
    } else {
      try {
        date = classItem.date?.toString() ?? '';
        time = classItem.time?.toString() ?? '';
        difficulty = classItem.difficulty?.toString() ?? '';
      } catch (e) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTitle(classItem),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            if (date.isNotEmpty) ...[
              const Icon(Icons.calendar_today, size: 14),
              const SizedBox(width: 6),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 12),
            ],
            if (time.isNotEmpty) ...[
              const Icon(Icons.schedule, size: 14),
              const SizedBox(width: 6),
              Text(time, style: Theme.of(context).textTheme.bodySmall),
            ],
            const Spacer(),
            if (difficulty.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(difficulty, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
        if (enableActions) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: _buildActions(classItem)),
        ],
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use shrinkWrap and disable inner scrolling so this ListView can be
    // placed inside another scrollable (e.g., SingleChildScrollView) without
    // causing an unbounded-height error.
    return ListView.builder(
      shrinkWrap: disableInnerScroll,
      physics: disableInnerScroll ? const NeverScrollableScrollPhysics() : null,
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classItem = classes[index];

        Widget child;
        switch (classListType) {
          case ClassListType.compact:
            child = _buildCompactItem(context, classItem);
            break;
          case ClassListType.card:
            child = _buildCardItem(context, classItem);
            break;
          case ClassListType.detailed:
            child = Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _buildDetailedItem(context, classItem),
            );
            break;
        }

        // If slidable is enabled and actions are allowed, wrap the child in a Slidable
        if (enableSlidable && enableActions) {
          // try to get a stable id for the key
          final keyId = (classItem is Map) ? (classItem['id'] ?? classItem['class_id'] ?? _getTitle(classItem)) : _getTitle(classItem);
          return Slidable(
            key: ValueKey(keyId),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) async {
                    try {
                      await onRegister(classItem);
                    } catch (e) {
                      // ignore
                    }
                  },
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  icon: Icons.check_circle,
                  label: 'Register',
                ),
              ],
            ),
            child: child,
          );
        }

        return child;
      },
    );
  }
}
