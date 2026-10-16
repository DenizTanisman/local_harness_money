/// Core seed data (spec 4.3). Inserted once in the onCreate migration.
class SeedCategory {
  const SeedCategory(this.direction, this.name, {this.essential = false});

  final String direction;
  final String name;
  final bool essential;
}

const List<SeedCategory> seedMoneyCategories = [
  SeedCategory('outcome', 'Rent', essential: true),
  SeedCategory('outcome', 'Bill', essential: true),
  SeedCategory('outcome', 'Food'),
  SeedCategory('outcome', 'Entertainment'),
  SeedCategory('income', 'Scholarship'),
];

/// Default app settings (spec 6.6).
const Map<String, String> seedSettings = {'backup_enabled': 'false'};
