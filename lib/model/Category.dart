class Category {
  /// Clave del json para el
  static const CATEGORY_KEY = 'category';

  /// Clave del json para el id del producto
  static const SUBCATEGORIES_KEY = 'sub_categories';

  /// Nombre de la collección a la que pertenecenen Firebase
  static const COLLECTION_KEY = 'categories';

  final String categoryName;
  Set<String> subCategories;

  Category(this.categoryName, this.subCategories);

  void addSubCategory(String newSubCategory){
    subCategories.add(newSubCategory);
  }

  void removeSubCategory(String subCategory){
    subCategories.remove(subCategory);
  }

  factory Category.fromJson(Map<String, dynamic> parsedJson) {
    var subCategoriesFromJson = parsedJson[SUBCATEGORIES_KEY];
    Set<String> subCategories = Set<String>.from(subCategoriesFromJson);

    Category newCategory = Category(parsedJson[CATEGORY_KEY], Set());
    subCategories.forEach((subCategory) => newCategory.addSubCategory(subCategory));

    return newCategory;
  }

  Map<String, dynamic> toJson() => {
    CATEGORY_KEY: categoryName,
    SUBCATEGORIES_KEY: subCategories.toList(),
  };

  @override
  int get hashCode => categoryName.hashCode;

  @override
  bool operator ==(other) {
    if(other is Category)
      return categoryName == other.categoryName;
    else
      return false;
  }
}