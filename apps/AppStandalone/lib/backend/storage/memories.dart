import 'package:sama/flutter_flow/flutter_flow_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryRecord {
  String id;
  DateTime date;
  String rawMemory;
  String structuredMemory;
  bool isEmpty;
  bool isUseless;

  MemoryRecord({
    required this.id,
    required this.date,
    required this.rawMemory,
    required this.structuredMemory,
    required this.isEmpty,
    required this.isUseless,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'rawMemory': rawMemory,
      'structuredMemory': structuredMemory,
      'isEmpty': isEmpty,
      'isUseless': isUseless,
    };
  }

  factory MemoryRecord.fromJson(Map<String, dynamic> json) {
    return MemoryRecord(
      id: json['id'],
      date: DateTime.parse(json['date']),
      rawMemory: json['rawMemory'],
      structuredMemory: json['structuredMemory'],
      isEmpty: json['isEmpty'],
      isUseless: json['isUseless'],
    );
  }
}

_savedMemoryCallback() async {
  var newMemories = await MemoryStorage.getAllMemories();
  FFAppState().update(() {
    FFAppState().memories = newMemories;
  });
}

class MemoryStorage {
  static const String _storageKey = 'memories';

  static Future<void> addMemory(MemoryRecord memory) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> allMemories = prefs.getStringList(_storageKey) ?? [];
    allMemories.add(jsonEncode(memory.toJson()));
    await prefs.setStringList(_storageKey, allMemories);
    _savedMemoryCallback();
  }

  static Future<List<MemoryRecord>> getAllMemories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> allMemories = prefs.getStringList(_storageKey) ?? [];
    List<MemoryRecord> memories =
        allMemories.reversed.map((memory) => MemoryRecord.fromJson(jsonDecode(memory))).toList();
    return memories.where((memory) => !memory.isUseless).toList();
  }

  static Future<void> updateMemory(String memoryId, String updatedMemory) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> allMemories = prefs.getStringList(_storageKey) ?? [];
    int index = allMemories.indexWhere((memory) => MemoryRecord.fromJson(jsonDecode(memory)).id == memoryId);
    if (index >= 0 && index < allMemories.length) {
      MemoryRecord oldMemory = MemoryRecord.fromJson(jsonDecode(allMemories[index]));
      MemoryRecord updatedRecord = MemoryRecord(
        id: oldMemory.id,
        date: oldMemory.date,
        rawMemory: oldMemory.rawMemory,
        structuredMemory: updatedMemory,
        isEmpty: updatedMemory.isEmpty,
        isUseless: updatedMemory.isEmpty,
      );
      allMemories[index] = jsonEncode(updatedRecord.toJson());
      await prefs.setStringList(_storageKey, allMemories);
    }
    _savedMemoryCallback();
  }

  static Future<void> deleteMemory(String memoryId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> allMemories = prefs.getStringList(_storageKey) ?? [];
    int index = allMemories.indexWhere((memory) => MemoryRecord.fromJson(jsonDecode(memory)).id == memoryId);
    if (index >= 0 && index < allMemories.length) {
      allMemories.removeAt(index);
      await prefs.setStringList(_storageKey, allMemories);
    }
    _savedMemoryCallback();
  }

  static Future<List<MemoryRecord>> getMemoriesByDay(DateTime day) async {
    List<MemoryRecord> allMemories = await getAllMemories();
    return allMemories.where((memory) => isSameDay(memory.date, day)).toList();
  }

  static Future<List<MemoryRecord>> getMemoriesOfLastWeek() async {
    DateTime now = DateTime.now();
    DateTime lastWeekStart = now.subtract(Duration(days: now.weekday + 6));
    DateTime lastWeekEnd = now.subtract(Duration(days: now.weekday));
    List<MemoryRecord> allMemories = await getAllMemories();
    return allMemories
        .where((memory) => memory.date.isAfter(lastWeekStart) && memory.date.isBefore(lastWeekEnd))
        .toList();
  }

  static Future<List<MemoryRecord>> getMemoriesOfLastMonth() async {
    DateTime now = DateTime.now();
    DateTime lastMonthStart = DateTime(now.year, now.month - 1, 1);
    DateTime lastMonthEnd = DateTime(now.year, now.month, 0);
    List<MemoryRecord> allMemories = await getAllMemories();
    return allMemories
        .where((memory) => memory.date.isAfter(lastMonthStart) && memory.date.isBefore(lastMonthEnd))
        .toList();
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}