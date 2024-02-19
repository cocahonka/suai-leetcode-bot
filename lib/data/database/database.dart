import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get telegramId => integer().unique()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();

  TextColumn get name => text().nullable().withLength(min: 2, max: 32)();
  TextColumn get groupNumber => text().nullable()();
}

class LeetCodeAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get user => integer().unique().references(Users, #id)();
  TextColumn get nickname => text().unique().withLength(min: 3, max: 32)();
  DateTimeColumn get dateOfAddition => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isGraduated => boolean().withDefault(const Constant(false))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 128)();
  TextColumn get shortTitle => text().withLength(min: 1, max: 16)();
  TextColumn get description => text().withLength(min: 1, max: 1024)();
  IntColumn get sortingNumber => integer()();
  DateTimeColumn get deadline => dateTime()();
}

enum LeetCodeTaskComplexity {
  easy,
  medium,
  hard;

  String get cutName => name[0].toUpperCase();
}

class LeetCodeTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slug => text().unique()();
  IntColumn get category => integer().references(Categories, #id)();
  TextColumn get title => text().withLength(min: 1, max: 128)();
  TextColumn get link => text().withLength(min: 1, max: 512)();
  TextColumn get complexity => textEnum<LeetCodeTaskComplexity>()();
}

class SolvedLeetCodeTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get user => integer().references(Users, #id)();
  IntColumn get task => integer().references(LeetCodeTasks, #id)();
  DateTimeColumn get date => dateTime()();
}

@DriftDatabase(
  tables: [
    Users,
    LeetCodeAccounts,
    Categories,
    LeetCodeTasks,
    SolvedLeetCodeTasks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final scriptFolderPath = File(Platform.script.toFilePath()).parent.path;
      final dbFolderPath = path.join(scriptFolderPath, 'db');

      final file = File(path.join(dbFolderPath, 'db.sqlite'));
      final cachebase = path.join(dbFolderPath, 'cache');

      sqlite3.tempDirectory = cachebase;

      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<bool> isLeetCodeNicknameAlreadyTaken(String leetCodeNickname) async {
    final leetCodeAccount = await (select(leetCodeAccounts)
          ..where((l) => l.nickname.equals(leetCodeNickname))
          ..limit(1))
        .getSingleOrNull();

    return leetCodeAccount != null;
  }

  Future<List<User>> get authorizedUsers => select(users).get();

  Future<List<LeetCodeAccount>> get activeLeetCodeAccounts =>
      (select(leetCodeAccounts)..where((l) => l.isGraduated.equals(false))).get();

  Future<List<Category>> get allCategories => (select(categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortingNumber),
        ]))
      .get();

  Future<Category> getCategory(int id) => (select(categories)..where((c) => c.id.equals(id))).getSingle();

  Future<List<LeetCodeTask>> getTasks(int categoryId) =>
      (select(leetCodeTasks)..where((l) => l.category.equals(categoryId))).get();

  Future<void> updateUserSubmissions({
    required int userId,
    required List<({String slug, int timestamp})> submissions,
  }) async {
    await batch((batch) async {
      for (final (:slug, :timestamp) in submissions) {
        final taskQuery = select(leetCodeTasks)
          ..where((l) => l.slug.equals(slug))
          ..limit(1);
        final task = await taskQuery.getSingleOrNull();

        if (task == null) return;

        final solvedTaskQuery = select(solvedLeetCodeTasks)
          ..where((st) => st.task.equals(task.id) & st.user.equals(userId))
          ..limit(1);
        final solvedTask = await solvedTaskQuery.getSingleOrNull();

        if (solvedTask != null) return;

        batch.insert(
          solvedLeetCodeTasks,
          SolvedLeetCodeTasksCompanion.insert(
            user: userId,
            task: task.id,
            date: DateTime.fromMillisecondsSinceEpoch(timestamp),
          ),
        );
      }
    });
  }

  Future<List<({LeetCodeTask task, bool isSolved})>> getTasksWithUserSolutions({
    required int categoryId,
    required int telegramId,
  }) async {
    final tasksInCategory = await (select(leetCodeTasks)..where((t) => t.category.equals(categoryId))).get();

    final user = await (select(users)
          ..where((u) => u.telegramId.equals(telegramId))
          ..limit(1))
        .getSingle();

    final solvedTaskIds =
        await (select(solvedLeetCodeTasks)..where((st) => st.user.equals(user.id))).map((row) => row.task).get();

    return tasksInCategory.map((task) {
      final isSolved = solvedTaskIds.contains(task.id);
      return (task: task, isSolved: isSolved);
    }).toList();
  }

  Future<void> createUserWithLeetCodeAccount({
    required int telegramId,
    required String name,
    required String groupNumber,
    required String leetCodeNickname,
  }) async {
    await transaction<void>(() async {
      final userId = await into(users).insert(
        UsersCompanion.insert(
          telegramId: telegramId,
          name: Value(name),
          groupNumber: Value(groupNumber),
        ),
      );
      await into(leetCodeAccounts).insert(
        LeetCodeAccountsCompanion.insert(
          user: userId,
          nickname: leetCodeNickname,
        ),
      );
    });
  }
}
