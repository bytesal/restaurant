import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

const String webAppUrl = "https://script.google.com/macros/s/AKfycbyCnd0DcFXHxJY9kkLYY8HFM282urHGizg9nhenV-rdq623liL0v7YdBDJjkeOpatGx/exec";

void main() {
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة الصالة',
      debugShowCheckedModeBanner: false,
      directionality: TextDirection.rtl,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DistributionPage(),
    const EmployeesPage(),
    const SectionsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shuffle), label: 'التوزيع اليومي'),
          NavigationDestination(icon: Icon(Icons.people), label: 'الموظفين'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'الكاريهات'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 1. شاشة إدارة الموظفين
// ---------------------------------------------------------
class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<dynamic> employees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$webAppUrl?action=getEmployees'));
      if (response.statusCode == 200) {
        setState(() {
          employees = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showAddEmployeeDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '8');
    String role = 'كابتن';
    String offDay = 'الجمعة';
    bool isTwoShifts = false;
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulWidget(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة موظف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الموظف')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
                TextField(controller: hoursCtrl, decoration: const InputDecoration(labelText: 'عدد ساعات الدوام'), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'المسمى الوظيفي'),
                  items: ['كابتن', 'كومي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => role = val!),
                ),
                DropdownButtonFormField<String>(
                  value: offDay,
                  decoration: const InputDecoration(labelText: 'يوم العطلة الأسبوعية'),
                  items: ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => offDay = val!),
                ),
                SwitchListTile(
                  title: const Text('شيفتين باليوم؟'),
                  value: isTwoShifts,
                  onChanged: (val) => setDialogState(() => isTwoShifts = val),
                ),
                Text('التقييم (الكفاءة): ${rating.toInt()} / 10'),
                Slider(
                  value: rating,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: rating.toInt().toString(),
                  onChanged: (val) => setDialogState(() => rating = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveEmployee({
                  'action': 'addEmployee',
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'hours': hoursCtrl.text,
                  'role': role,
                  'offDay': offDay,
                  'isTwoShifts': isTwoShifts,
                  'rating': rating.toInt(),
                });
                fetchEmployees();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEmployee(Map<String, dynamic> data) async {
    await http.post(Uri.parse(webAppUrl), body: json.encode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الموظفين')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (ctx, i) {
                final emp = employees[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(emp['Role'] == 'كابتن' ? 'C' : 'K')),
                    title: Text(emp['Name'] ?? ''),
                    subtitle: Text('العطلة: ${emp['OffDay']} | الساعات: ${emp['Hours']} | الشيفتين: ${emp['TwoShifts']}'),
                    trailing: Chip(
                      label: Text('${emp['Rating']}/10'),
                      backgroundColor: Colors.deepOrange.shade100,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------
// 2. شاشة إدارة الكاريهات
// ---------------------------------------------------------
class SectionsPage extends StatefulWidget {
  const SectionsPage({super.key});

  @override
  State<SectionsPage> createState() => _SectionsPageState();
}

class _SectionsPageState extends State<SectionsPage> {
  List<dynamic> sections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSections();
  }

  Future<void> fetchSections() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$webAppUrl?action=getSections'));
      if (response.statusCode == 200) {
        setState(() {
          sections = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showAddSectionDialog() {
    final nameCtrl = TextEditingController();
    bool isBusy = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulWidget(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة كاري جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم / رقم الكاري')),
              SwitchListTile(
                title: const Text('عالي الازدحام؟ (أيام الخميس والجمعة)'),
                value: isBusy,
                onChanged: (val) => setDialogState(() => isBusy = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await http.post(Uri.parse(webAppUrl), body: json.encode({
                  'action': 'addSection',
                  'name': nameCtrl.text,
                  'isBusy': isBusy,
                }));
                fetchSections();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الكاريهات')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSectionDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: sections.length,
              itemBuilder: (ctx, i) {
                final sec = sections[i];
                final isBusy = sec['IsBusy'] == 'عالي الازدحام';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Icon(Icons.table_restaurant, color: isBusy ? Colors.red : Colors.green),
                    title: Text(sec['Name'] ?? ''),
                    subtitle: Text(sec['IsBusy'] ?? 'عادي'),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------
// 3. شاشة التوزيع اليومي الذكي
// ---------------------------------------------------------
class DistributionPage extends StatefulWidget {
  const DistributionPage({super.key});

  @override
  State<DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends State<DistributionPage> {
  String selectedDay = 'الخميس';
  String selectedShift = 'صباحي';
  List<Map<String, String>> assignments = [];
  bool isCalculating = false;

  final List<String> days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

  Future<void> _generateSmartDistribution() async {
    setState(() => isCalculating = true);
    try {
      final empRes = await http.get(Uri.parse('$webAppUrl?action=getEmployees'));
      final secRes = await http.get(Uri.parse('$webAppUrl?action=getSections'));

      List<dynamic> allEmployees = json.decode(empRes.body);
      List<dynamic> allSections = json.decode(secRes.body);

      // 1. تصفية الموظفين المتاحين (استبعاد أصحاب العطلة)
      List<dynamic> availableEmps = allEmployees.where((e) => e['OffDay'] != selectedDay).toList();

      // 2. فحص هل اليوم ذروة (خميس أو جمعة)
      bool isPeakDay = (selectedDay == 'الخميس' || selectedDay == 'الجمعة');

      if (isPeakDay) {
        // ترتيب الموظفين حسب التقييم الأقوى أولاً
        availableEmps.sort((a, b) => (b['Rating'] as num).compareTo(a['Rating'] as num));
        // ترتيب الكاريهات لتكون المزدحمة أولاً
        allSections.sort((a, b) => (b['IsBusy'] == 'عالي الازدحام' ? 1 : 0).compareTo(a['IsBusy'] == 'عالي الازدحام' ? 1 : 0));
      } else {
        // خلط عشوائي في الأيام العادية
        availableEmps.shuffle(Random());
      }

      // 3. إجراء عملية الإسناد
      List<Map<String, String>> result = [];
      for (int i = 0; i < allSections.length; i++) {
        if (i < availableEmps.length) {
          result.add({
            'sectionName': allSections[i]['Name'].toString(),
            'employeeName': availableEmps[i]['Name'].toString(),
            'role': availableEmps[i]['Role'].toString(),
          });
        }
      }

      setState(() {
        assignments = result;
        isCalculating = false;
      });
    } catch (e) {
      setState(() => isCalculating = false);
    }
  }

  Future<void> _saveAssignmentsToSheet() async {
    if (assignments.isEmpty) return;
    final body = {
      'action': 'saveAssignment',
      'assignments': assignments.map((a) => {
        'date': DateTime.now().toString().split(' ')[0],
        'shift': selectedShift,
        'employeeName': a['employeeName'],
        'role': a['role'],
        'sectionName': a['sectionName'],
      }).toList(),
    };

    await http.post(Uri.parse(webAppUrl), body: json.encode(body));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التوزيع بفرع Google Sheet بنجاح!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التوزيع اليومي الذكي')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: const InputDecoration(labelText: 'اختر اليوم'),
                    items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) => setState(() => selectedDay = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedShift,
                    decoration: const InputDecoration(labelText: 'الشيفت'),
                    items: ['صباحي', 'مسائي'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => selectedShift = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _generateSmartDistribution,
              icon: const Icon(Icons.psychology),
              label: const Text('توليد التوزيع تلقائياً'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
            ),
            const Divider(height: 30),
            Expanded(
              child: isCalculating
                  ? const Center(child: CircularProgressIndicator())
                  : assignments.isEmpty
                      ? const Center(child: Text('اضغط على "توليد التوزيع" للبدء'))
                      : ListView.builder(
                          itemCount: assignments.length,
                          itemBuilder: (ctx, i) {
                            final item = assignments[i];
                            return ListTile(
                              leading: const Icon(Icons.person_pin),
                              title: Text('كاري: ${item['sectionName']}'),
                              subtitle: Text('الموظف: ${item['employeeName']} (${item['role']})'),
                            );
                          },
                        ),
            ),
            if (assignments.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _saveAssignmentsToSheet,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('اعتماد وحفظ التوزيع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
