import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:formatic/core/theme/button_styles.dart';
import 'package:formatic/features/tasks/widgets/task_card_modern.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Task {
  final int? id;
  final String name;
  final String description;
  final Color color;
  final DateTime date;

  Task({
    this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'color': _colorToHex(color),
    'date': date.toIso8601String(),
  };

  static String _colorToHex(Color c) {
    // Gera string #AARRGGBB usando os novos acessores
    int a = (c.a * 255.0).round() & 0xff;
    int r = (c.r * 255.0).round() & 0xff;
    int g = (c.g * 255.0).round() & 0xff;
    int b = (c.b * 255.0).round() & 0xff;
    return '#'
            '${a.toRadixString(16).padLeft(2, '0')}'
            '${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  factory Task.fromJson(Map<String, dynamic> map) => Task(
    id: map['id'] is int
        ? map['id']
        : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
    name: map['name'] as String,
    description: map['description'] as String,
    color: _parseColor(map['color'] as String),
    date: DateTime.parse(map['date'] as String),
  );

  static Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
    }
    if (colorString.length == 8) {
      return Color(int.parse(colorString, radix: 16));
    } else if (colorString.length == 6) {
      return Color(int.parse('FF$colorString', radix: 16));
    }
    return Colors.blue;
  }
}

class TaskManagerPage extends StatefulWidget {
  final bool isDarkMode;
  const TaskManagerPage({super.key, this.isDarkMode = false});

  @override
  State<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends State<TaskManagerPage> {
  List<Task> _tasks = [];
  final String _prefsKey = 'tasks';
  final ScrollController _scrollController = ScrollController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      setState(() {
        _tasks = data.map((e) => Task.fromJson(e)).toList();
      });
    }
  }

  Future<void> _addTask(Task task) async {
    setState(() {
      _tasks.add(task);
    });
    await _saveTasks();
  }

  Future<void> _updateTask(Task task, int index) async {
    setState(() {
      _tasks[index] = task;
    });
    await _saveTasks();
  }

  Future<void> _deleteTask(int index) async {
    setState(() {
      _tasks.removeAt(index);
    });
    await _saveTasks();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_tasks.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, jsonString);
  }

  void _showAddTaskDialog({Task? editTask, int? editIndex}) {
    String name = editTask?.name ?? '';
    String description = editTask?.description ?? '';
    final List<Color> availableColors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.orange,
      Colors.green,
    ];
    Color color = editTask?.color ?? availableColors[0];
    DateTime? date = editTask?.date;
    TimeOfDay? time = editTask != null
        ? TimeOfDay(hour: editTask.date.hour, minute: editTask.date.minute)
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                editTask == null ? 'Nova Tarefa' : 'Editar Tarefa',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nome'),
                      controller: TextEditingController(text: name),
                      onChanged: (v) => name = v,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      controller: TextEditingController(text: description),
                      onChanged: (v) => description = v,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Cor:'),
                        const SizedBox(width: 8),
                        Row(
                          children: availableColors
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setStateDialog(() => color = c),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color == c
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        backgroundColor: c,
                                        radius: 14,
                                        child: color == c
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 18,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Data:'),
                        const SizedBox(width: 8),
                        Text(
                          date == null
                              ? 'Selecione'
                              : '${date!.day}/${date!.month}/${date!.year}',
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date ?? now,
                              firstDate: DateTime(now.year - 2),
                              lastDate: DateTime(now.year + 5),
                            );
                            if (picked != null) {
                              setStateDialog(() => date = picked);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('Hora:'),
                        const SizedBox(width: 8),
                        Text(time?.format(context) ?? '--:--'),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: time ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() => time = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(editTask == null ? 'Salvar' : 'Atualizar'),
                  onPressed: () async {
                    if (name.isNotEmpty && date != null && time != null) {
                      final dateTimeWithTime = DateTime(
                        date!.year,
                        date!.month,
                        date!.day,
                        time!.hour,
                        time!.minute,
                      );
                      if (editTask == null) {
                        await _addTask(
                          Task(
                            name: name,
                            description: description,
                            color: color,
                            date: dateTimeWithTime,
                          ),
                        );
                      } else if (editIndex != null) {
                        await _updateTask(
                          Task(
                            id: editTask.id,
                            name: name,
                            description: description,
                            color: color,
                            date: dateTimeWithTime,
                          ),
                          editIndex,
                        );
                      }
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final today = DateTime.now();
    // Filtragem por busca
    final filteredTasks = _searchQuery.isEmpty
        ? _tasks
        : _tasks
              .where(
                (t) =>
                    t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    t.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    final todayTasks = filteredTasks
        .where(
          (t) =>
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .toList();
    final monthTasks = filteredTasks
        .where(
          (t) => t.date.year == _selectedYear && t.date.month == _selectedMonth,
        )
        .toList();
    final allTasks = List<Task>.from(filteredTasks)
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final weekDayOffset = firstDayOfMonth.weekday % 7;
    final days = List.generate(daysInMonth, (i) => i + 1);
    final taskDays = monthTasks.map((t) => t.date.day).toSet();
    void scrollToTaskOfDay(int day) {
      final idx = allTasks.indexWhere(
        (t) =>
            t.date.day == day &&
            t.date.month == _selectedMonth &&
            t.date.year == _selectedYear,
      );
      if (idx != -1) {
        _scrollController.animateTo(
          idx * 100.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }

    final List<String> monthNames = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    // final List<int> yearList = List.generate(8, (i) => today.year - 2 + i);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // Barra de busca
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Pesquisar Tarefas',
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(fontSize: 16),
                              onChanged: (v) {
                                setState(() {
                                  _searchQuery = v;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF8B2CF5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.filter_alt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tarefas para hoje
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tarefas para hoje',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Ver todas',
                      style: TextStyle(
                        color: Color(0xFF8B2CF5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (todayTasks.isEmpty)
                Text(
                  'Nenhuma tarefa para hoje',
                  style: TextStyle(
                    color: textColor.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              if (todayTasks.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: todayTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final t = todayTasks[i];
                      return TaskCardModern(
                        task: t,
                        onEdit: () => _showAddTaskDialog(
                          editTask: t,
                          editIndex: _tasks.indexOf(t),
                        ),
                        onDelete: () async {
                          final idx = _tasks.indexOf(t);
                          if (idx != -1) await _deleteTask(idx);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 28),
              // Calendário
              const Text(
                'Calendário',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF8B2CF5),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_selectedMonth == 1) {
                                _selectedMonth = 12;
                                _selectedYear--;
                              } else {
                                _selectedMonth--;
                              }
                            });
                          },
                        ),
                        Text(
                          '${monthNames[_selectedMonth - 1]} $_selectedYear',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_selectedMonth == 12) {
                                _selectedMonth = 1;
                                _selectedYear++;
                              } else {
                                _selectedMonth++;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                              .map(
                                (d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 0,
                      runSpacing: 0,
                      children: [
                        for (int i = 0; i < weekDayOffset; i++)
                          const SizedBox(width: 36, height: 36),
                        for (final d in days)
                          GestureDetector(
                            onTap: taskDays.contains(d)
                                ? () => scrollToTaskOfDay(d)
                                : null,
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: taskDays.contains(d)
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  d.toString(),
                                  style: TextStyle(
                                    color: taskDays.contains(d)
                                        ? Color(0xFF8B2CF5)
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Todas as tarefas
              const Text(
                'Todas as tarefas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              if (allTasks.isEmpty)
                Text(
                  'Nenhuma tarefa criada',
                  style: TextStyle(
                    color: textColor.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: allTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final t = allTasks[i];
                    return TaskCardModern(
                      task: t,
                      onEdit: () => _showAddTaskDialog(
                        editTask: t,
                        editIndex: _tasks.indexOf(t),
                      ),
                      onDelete: () async {
                        final idx = _tasks.indexOf(t);
                        if (idx != -1) await _deleteTask(idx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
          // Botão Nova Tarefa fixo na parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: purpleElevatedStyle(radius: 16),
                  onPressed: () => _showAddTaskDialog(),
                  child: const Text(
                    'Nova Tarefa',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
