import 'package:flutter/material.dart';

class IconHelper {
  /// String isminden IconData döndürür. Bulamazsa varsayılan ikonu verir.
  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.restaurant;
    return _iconMap[iconName] ?? Icons.restaurant;
  }

  /// AI'ın seçim yapabileceği ikon listesi
  static final Map<String, IconData> _iconMap = {
    // Genel
    'restaurant': Icons.restaurant,
    'restaurant_menu': Icons.restaurant_menu,
    'menu_book': Icons.menu_book,
    'local_dining': Icons.local_dining,
    'dinner_dining': Icons.dinner_dining,
    'lunch_dining': Icons.lunch_dining,
    'breakfast_dining': Icons.breakfast_dining,
    'brunch_dining': Icons.brunch_dining,
    'fastfood': Icons.fastfood,
    'food_bank': Icons.food_bank,
    'takeout_dining': Icons.takeout_dining,
    'delivery_dining': Icons.delivery_dining,
    'category': Icons.category,
    'stars': Icons.stars,
    
    // Yemekler
    'soup_kitchen': Icons.soup_kitchen, // Çorba
    'local_pizza': Icons.local_pizza, // Pizza
    'rice_bowl': Icons.rice_bowl, // Pilav, Sulu yemek
    'kebab_dining': Icons.kebab_dining, // Kebap
    'tapas': Icons.tapas, // Atıştırmalık, Meze
    'bento': Icons.bento, // Kutu yemek
    'bakery_dining': Icons.bakery_dining, // Fırın, Ekmek
    'set_meal': Icons.set_meal, // Menü
    'ramen_dining': Icons.ramen_dining, // Makarna, Erişte
    'kitchen': Icons.kitchen, 
    'egg': Icons.egg, // Kahvaltı
    'egg_alt': Icons.egg_alt,
    
    // İçecekler
    'local_cafe': Icons.local_cafe, // Kahve
    'coffee': Icons.coffee,
    'coffee_maker': Icons.coffee_maker,
    'local_bar': Icons.local_bar, // İçki, Kokteyl
    'liquor': Icons.liquor,
    'wine_bar': Icons.wine_bar,
    'nightlife': Icons.nightlife,
    'local_drink': Icons.local_drink, // Su, Meşrubat
    'water_drop': Icons.water_drop,
    'emoji_food_beverage': Icons.emoji_food_beverage, // Çay vb.
    'sports_bar': Icons.sports_bar, // Bira
    
    // Tatlılar
    'cake': Icons.cake, // Pasta
    'icecream': Icons.icecream, // Dondurma
    'cookie': Icons.cookie, // Kurabiye
    'celebration': Icons.celebration,
    
    // Meyve/Sebze (Salata)
    'grass': Icons.grass, // Yeşillik
    'eco': Icons.eco, // Vegan/Salata
    'agriculture': Icons.agriculture,
    'park': Icons.park, // Doğa/Salata çağrışımı 
    'nutrition': Icons.spa, // Sağlıklı
    
    // Deniz Ürünleri
    'sailing': Icons.sailing, // Balık (Sembolik)
    'water': Icons.water,
    
    // Diğer - Sokak Lezzetleri vb.
    'local_fire_department': Icons.local_fire_department, // Acılı, Sıcak, Izgara
    'whatshot': Icons.whatshot, // Popüler, Sıcak
    'star': Icons.star, // Özel
    'favorite': Icons.favorite, // Favori
    'bolt': Icons.bolt, // Hızlı
    'shopping_basket': Icons.shopping_basket,
    'storefront': Icons.storefront, 
  };
  
  // Prompt için bu listeyi string olarak alacağız
  static String get availableIconsString => _iconMap.keys.join(', ');
}
