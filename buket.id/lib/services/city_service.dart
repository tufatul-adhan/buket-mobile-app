import '../models/city.dart';

class CityService {
  static const List<City> jabodetabek = [
    City(id: '1', name: 'Jakarta Pusat', province: 'DKI Jakarta'),
    City(id: '2', name: 'Jakarta Selatan', province: 'DKI Jakarta'),
    City(id: '3', name: 'Jakarta Timur', province: 'DKI Jakarta'),
    City(id: '4', name: 'Jakarta Barat', province: 'DKI Jakarta'),
    City(id: '5', name: 'Jakarta Utara', province: 'DKI Jakarta'),
    City(id: '6', name: 'Bogor', province: 'Jawa Barat'),
    City(id: '7', name: 'Depok', province: 'Jawa Barat'),
    City(id: '8', name: 'Tangerang', province: 'Banten'),
    City(id: '9', name: 'Tangerang Selatan', province: 'Banten'),
    City(id: '10', name: 'Bekasi', province: 'Jawa Barat'),
  ];

  List<City> getCities() => jabodetabek;

  City? getCityById(String id) {
    try {
      return jabodetabek.firstWhere((city) => city.id == id);
    } catch (e) {
      return null;
    }
  }

  City? getCityByName(String name) {
    try {
      return jabodetabek.firstWhere((city) => city.name == name);
    } catch (e) {
      return null;
    }
  }
}
