import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:suai_leetcode_bot/bot/scopes/admin/admin_scope.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get telegramId => integer().unique()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();

  TextColumn get name => text().nullable().withLength(min: 5, max: 32)();
  TextColumn get groupNumber => text().nullable()();
}

class LeetCodeAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get user => integer().unique().references(Users, #id)();
  TextColumn get nickname => text().unique().withLength(min: 3, max: 32)();
  DateTimeColumn get dateOfAddition =>
      dateTime().withDefault(currentDateAndTime)();
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
  IntColumn get category =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 128)();
  TextColumn get link => text().withLength(min: 1, max: 512)();
  TextColumn get complexity => textEnum<LeetCodeTaskComplexity>()();
}

class SolvedLeetCodeTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get user => integer().references(Users, #id)();
  IntColumn get task =>
      integer().references(LeetCodeTasks, #id, onDelete: KeyAction.cascade)();
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

  Future<bool> isAdmin(int telegramId) async {
    final user = await (select(users)
          ..where((usr) => usr.telegramId.equals(telegramId))
          ..limit(1))
        .getSingleOrNull();
    return user?.isAdmin ?? false;
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
      (select(leetCodeAccounts)..where((l) => l.isGraduated.equals(false)))
          .get();

  Future<List<Category>> get allCategories => (select(categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortingNumber),
        ]))
      .get();

  Future<List<({Category category, List<LeetCodeTask> tasks})>>
      get tasksByCategories async {
    final categories = await allCategories;
    return Future.wait(
      List.generate(categories.length, (index) async {
        return (
          category: categories[index],
          tasks: await getTasks(categories[index].id),
        );
      }),
    );
  }

  Future<Category> getCategory(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingle();

  Future<List<LeetCodeTask>> getTasks(int categoryId) =>
      (select(leetCodeTasks)..where((l) => l.category.equals(categoryId)))
          .get();

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
    await deleteSolvedDuplications();
  }

  Future<List<({LeetCodeTask task, bool isSolved})>> getTasksWithUserSolutions({
    required int categoryId,
    required int telegramId,
  }) async {
    final tasksInCategory = await (select(leetCodeTasks)
          ..where((t) => t.category.equals(categoryId)))
        .get();

    final user = await (select(users)
          ..where((u) => u.telegramId.equals(telegramId))
          ..limit(1))
        .getSingle();

    final solvedTaskIds = await (select(solvedLeetCodeTasks)
          ..where((st) => st.user.equals(user.id)))
        .map((row) => row.task)
        .get();

    return tasksInCategory.map((task) {
      final isSolved = solvedTaskIds.contains(task.id);
      return (task: task, isSolved: isSolved);
    }).toList();
  }

  Future<void> deleteSolvedDuplications() async {
    final allEntries = await select(solvedLeetCodeTasks).get();

    final groupedEntries = <(int, int), List<SolvedLeetCodeTask>>{};
    for (final entry in allEntries) {
      final key = (entry.user, entry.task);
      groupedEntries.putIfAbsent(key, () => []).add(entry);
    }

    final idsToDelete = <int>[];
    for (final group in groupedEntries.values) {
      if (group.length > 1) {
        group.sort((a, b) => a.date.compareTo(b.date));
        idsToDelete.addAll(group.skip(1).map((e) => e.id));
      }
    }

    for (final id in idsToDelete) {
      await (delete(solvedLeetCodeTasks)..where((t) => t.id.equals(id))).go();
    }
  }

  Future<List<CategoryRating>> getRatingPerCategory() async {
    final nonEmptyCategories = await (select(categories)
          ..where(
            (cat) => existsQuery(
              select(leetCodeTasks)
                ..where((task) => task.category.equalsExp(cat.id))
                ..limit(1),
            ),
          )
          ..orderBy([
            (cat) => OrderingTerm.asc(cat.sortingNumber),
          ]))
        .get();

    final categoriesTasks = <List<LeetCodeTask>>[];
    final usersWithProgress = <List<User>>[];
    for (final cat in nonEmptyCategories) {
      categoriesTasks.add(
        await (select(leetCodeTasks)
              ..where((lct) => lct.category.equals(cat.id)))
            .get(),
      );

      final categoriesTasksIds = categoriesTasks.last.map((c) => c.id).toList();

      usersWithProgress.add(
        await (select(users)
              ..where(
                (usr) => existsQuery(
                  select(solvedLeetCodeTasks)
                    ..where(
                      (slv) =>
                          slv.user.equalsExp(usr.id) &
                          slv.task.isIn(categoriesTasksIds),
                    ),
                ),
              ))
            .get(),
      );
    }

    final categoriesRating = <CategoryRating>[];
    for (final (catIndex, cat) in nonEmptyCategories.indexed) {
      final tasks = categoriesTasks[catIndex];
      final tasksIds = tasks.map((t) => t.id).toList();
      final usersSubmissions = await Future.wait(
        List.generate(usersWithProgress[catIndex].length, (usrIndex) async {
          final userWithProgress = usersWithProgress[catIndex][usrIndex];
          final account = await (select(leetCodeAccounts)
                ..where((lca) => lca.user.equals(userWithProgress.id))
                ..limit(1))
              .getSingle();
          final solvedTasks = await (select(solvedLeetCodeTasks)
                ..where(
                  (slv) =>
                      slv.user.equals(userWithProgress.id) &
                      slv.task.isIn(tasksIds),
                ))
              .get();
          return UserLeetCodeSubmissions(
            user: userWithProgress,
            account: account,
            solvedTasks: solvedTasks,
          );
        }),
      );

      categoriesRating.add(
        CategoryRating(
          category: cat,
          tasks: tasks,
          usersSubmissions: usersSubmissions
            ..sort(
              (a, b) => b.solvedTasks.length.compareTo(a.solvedTasks.length),
            ),
        ),
      );
    }

    return categoriesRating;
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

  Future<(Object e, StackTrace s)?> processCRUD(
    CRUDOperations operations,
  ) async {
    try {
      await transaction<void>(() async {
        final (categories: categoriesOperations, tasks: tasksOperations) =
            operations;

        for (final categoryCreate in categoriesOperations.create) {
          categoryCreate as Map<String, dynamic>;
          final title = categoryCreate['title'] as String;
          final shortTitle = categoryCreate['shortTitle'] as String;
          final description = categoryCreate['description'] as String;
          final sortingNumber = categoryCreate['sortingNumber'] as int;

          await into(categories).insert(
            CategoriesCompanion.insert(
              title: title,
              shortTitle: shortTitle,
              description: description,
              sortingNumber: sortingNumber,
              deadline: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
        }

        for (final categoryUpdate in categoriesOperations.update) {
          categoryUpdate as Map<String, dynamic>;
          final id = categoryUpdate['id'] as int;
          final title = categoryUpdate['title'] as String?;
          final shortTitle = categoryUpdate['shortTitle'] as String?;
          final description = categoryUpdate['description'] as String?;
          final sortingNumber = categoryUpdate['sortingNumber'] as int?;

          final oldValue = await (select(categories)
                ..where((c) => c.id.equals(id))
                ..limit(1))
              .getSingle();

          final newValue = oldValue.copyWith(
            title: title,
            shortTitle: shortTitle,
            description: description,
            sortingNumber: sortingNumber,
          );

          await update(categories).replace(newValue);
        }

        for (final categoryDelete in categoriesOperations.delete) {
          categoryDelete as Map<String, dynamic>;
          final id = categoryDelete['id'] as int;

          await (delete(categories)..where((c) => c.id.equals(id))).go();
        }

        for (final taskCreate in tasksOperations.create) {
          taskCreate as Map<String, dynamic>;
          final slug = taskCreate['slug'] as String;
          final category = taskCreate['category'] as int;
          final title = taskCreate['title'] as String;
          final link = taskCreate['link'] as String;
          final complexity = taskCreate['complexity'] as String;

          await into(leetCodeTasks).insert(
            LeetCodeTasksCompanion.insert(
              slug: slug,
              category: category,
              title: title,
              link: link,
              complexity: LeetCodeTaskComplexity.values.firstWhere(
                (e) => e.name.toLowerCase() == complexity.toLowerCase(),
              ),
            ),
          );
        }

        for (final taskUpdate in tasksOperations.update) {
          taskUpdate as Map<String, dynamic>;
          final slug = taskUpdate['slug'] as String;
          final category = taskUpdate['category'] as int?;
          final title = taskUpdate['title'] as String?;
          final link = taskUpdate['link'] as String?;
          final complexity = taskUpdate['complexity'] as String?;

          final oldValue = await (select(leetCodeTasks)
                ..where((l) => l.slug.equals(slug))
                ..limit(1))
              .getSingle();

          final newValue = oldValue.copyWith(
            category: category,
            title: title,
            link: link,
            complexity: complexity == null
                ? null
                : LeetCodeTaskComplexity.values.firstWhere(
                    (e) => e.name.toLowerCase() == complexity.toLowerCase(),
                  ),
          );

          await update(leetCodeTasks).replace(newValue);
        }

        for (final taskDelete in tasksOperations.delete) {
          taskDelete as Map<String, dynamic>;
          final slug = taskDelete['slug'] as String;

          await (delete(leetCodeTasks)..where((l) => l.slug.equals(slug))).go();
        }
      });
    } on Object catch (e, s) {
      return (e, s);
    }
    return null;
  }
}

@immutable
final class CategoryRating {
  const CategoryRating({
    required this.category,
    required this.tasks,
    required this.usersSubmissions,
  });

  final Category category;
  final List<LeetCodeTask> tasks;
  final List<UserLeetCodeSubmissions> usersSubmissions;
}

@immutable
final class UserLeetCodeSubmissions {
  const UserLeetCodeSubmissions({
    required this.user,
    required this.account,
    required this.solvedTasks,
  });
  final User user;
  final LeetCodeAccount account;
  final List<SolvedLeetCodeTask> solvedTasks;

  UserLeetCodeSubmissions copyWith({
    User? user,
    LeetCodeAccount? account,
    List<SolvedLeetCodeTask>? solvedTasks,
  }) =>
      UserLeetCodeSubmissions(
        user: user ?? this.user,
        account: account ?? this.account,
        solvedTasks: solvedTasks ?? this.solvedTasks,
      );
}
