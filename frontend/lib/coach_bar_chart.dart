import 'dart:collection';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BarChartCoach extends StatefulWidget {
  BarChartCoach({super.key});
  final Color leftBarColor = AppColors.primaryPeach;
  final Color rightBarColor = AppColors.linkBlue;
  final Color avgColor =
      AppColors.lightPink;
  @override
  State<StatefulWidget> createState() => BarChartState();
}

Future<Map> fetchAttendanceRate() async {
    Map<int, double> map = HashMap();
    final supabase = Supabase.instance.client;
    for (int i = 1; i <= 12; i++) {
      var list = await supabase.rpc('get_created_class_list', params: {'month_input': i}); // returns a list of class id
      int size = list.length;
      double probability = 0.0;

      for (int class_id in list) {
        probability += await supabase.rpc('get_attendance_rate', params: {'given_id': class_id});
      }
      var attendance_rate = size==0? 0.0: probability/size;
      final dataOf1Month = {i: attendance_rate};
      map.addAll(dataOf1Month);
    }
    print(map);
    return map; 
}

class BarChartState extends State<BarChartCoach> {
  final double width = 7;
  late Map<int, double> map;

  late List<BarChartGroupData> rawBarGroups = [];
  late List<BarChartGroupData> showingBarGroups = [];

  int touchedGroupIndex = -1;
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { 
        isLoading = true; 
        loadError = null; 
    });
    try {
      await _loadData();
      setState(() { 
        isLoading = false;
      });
    } catch (err) {
      setState(() { 
        isLoading = false; 
        loadError = err.toString(); 
        showingBarGroups = []; 
      });
    }
  }

  Future<void> _loadData() async {
    map = (await fetchAttendanceRate()).cast<int, double>();
    final barGroup1 = makeGroupData(0, map[1] ?? 0);
    final barGroup2 = makeGroupData(1, map[2] ?? 0);
    final barGroup3 = makeGroupData(2, map[3] ?? 0);
    final barGroup4 = makeGroupData(3, map[4] ?? 0);
    final barGroup5 = makeGroupData(4, map[5] ?? 0);
    final barGroup6 = makeGroupData(5, map[6] ?? 0);
    final barGroup7 = makeGroupData(6, map[7] ?? 0);
    final barGroup8 = makeGroupData(7, map[8] ?? 0);
    final barGroup9 = makeGroupData(8, map[9] ?? 0);
    final barGroup10 = makeGroupData(9, map[10] ?? 0);
    final barGroup11 = makeGroupData(10, map[11] ?? 0);
    final barGroup12 = makeGroupData(11, map[12] ?? 0);

    final items = [
      barGroup1,
      barGroup2,
      barGroup3,
      barGroup4,
      barGroup5,
      barGroup6,
      barGroup7,
      barGroup8,
      barGroup9,
      barGroup10,
      barGroup11,
      barGroup12,
    ];

    rawBarGroups = items;
    showingBarGroups = rawBarGroups;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                makeTransactionsIcon(),
                const SizedBox(
                  width: 38,
                ),
                const Text(
                  'Transactions',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(
                  width: 4,
                ),
                const Text(
                  'Average Attendance Rate for 2025',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 10),
                ),
              ],
            ),
            const SizedBox(
              height: 38,
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : loadError != null
                      ? Center(child: Text(loadError!))
                      : BarChart(
                BarChartData(
                  maxY: 20,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: ((group) {
                        return Colors.grey;
                      }),
                      getTooltipItem: (a, b, c, d) => null,
                    ),
                    touchCallback: (FlTouchEvent event, response) {
                      if (response == null || response.spot == null) {
                        setState(() {
                          touchedGroupIndex = -1;
                          showingBarGroups = List.of(rawBarGroups);
                        });
                        return;
                      }

                      touchedGroupIndex = response.spot!.touchedBarGroupIndex;

                      setState(() {
                        if (!event.isInterestedForInteractions) {
                          touchedGroupIndex = -1;
                          showingBarGroups = List.of(rawBarGroups);
                          return;
                        }
                        showingBarGroups = List.of(rawBarGroups);
                        if (touchedGroupIndex != -1) {
                          var sum = 0.0;
                          for (final rod
                              in showingBarGroups[touchedGroupIndex].barRods) {
                            sum += rod.toY;
                          }
                          final avg = sum /
                              showingBarGroups[touchedGroupIndex]
                                  .barRods
                                  .length;

                          showingBarGroups[touchedGroupIndex] =
                              showingBarGroups[touchedGroupIndex].copyWith(
                            barRods: showingBarGroups[touchedGroupIndex]
                                .barRods
                                .map((rod) {
                              return rod.copyWith(
                                  toY: avg, color: widget.avgColor);
                            }).toList(),
                          );
                        }
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        reservedSize: 42,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: leftTitles,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: showingBarGroups,
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    if (value == 0) {
      text = '0%';
    } else if (value == 10) {
      text = '10%';
    } else if (value == 20) {
      text = '20%';
    } else {
      return Container();
    }
    return SideTitleWidget(
      meta: meta,
      space: 0,
      child: Text(text, style: style),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final titles = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 
    'Oct', 'Nov', 'Dec'];

    final Widget text = Text(
      titles[value.toInt()],
      style: const TextStyle(
        color: Color(0xff7589a2),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );

    return SideTitleWidget(
      meta: meta,
      space: 16, //margin top
      child: text,
    );
  }

  BarChartGroupData makeGroupData(int x, double y1) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: widget.leftBarColor,
          width: width,
        ),
      ],
    );
  }

  Widget makeTransactionsIcon() {
    const width = 4.5;
    const space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: width,
          height: 10,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 42,
          color: Colors.white.withValues(alpha: 1),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 10,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}
