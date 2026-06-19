import '../models/home_data.dart';

abstract interface class HomeRepository {
  Future<HomeData> loadHome();
}
