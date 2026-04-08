import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_url.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/models.dart';

sealed class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProduct();
  Future<void> createProduct(CreateProductModel model);
  Future<void> updateProduct(UpdateProductModel model);
  Future<void> deleteProduct(DeleteProductModel model);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  const ProductRemoteDataSourceImpl();

  @override
  Future<List<ProductModel>> fetchProduct() async {
    try {
      final box = await Hive.openBox<Map>(ApiUrl.productsBox);
      return box.values.map((e) => ProductModel.fromMap(e)).toList();
    } catch (e) {
      logger.e(e);
      throw ServerException();
    }
  }

  @override
  Future<void> createProduct(CreateProductModel model) async {
    try {
      final box = await Hive.openBox<Map>(ApiUrl.productsBox);
      final id = const Uuid().v4();
      await box.put(id, {
        "product_id": id,
        "name": model.name,
        "price": model.price,
      });
      return;
    } catch (e) {
      logger.e(e);
      throw ServerException();
    }
  }

  @override
  Future<void> deleteProduct(DeleteProductModel model) async {
    try {
      final box = await Hive.openBox<Map>(ApiUrl.productsBox);
      await box.delete(model.productId);
      return;
    } catch (e) {
      logger.e(e);
      throw ServerException();
    }
  }

  @override
  Future<void> updateProduct(UpdateProductModel model) async {
    try {
      final box = await Hive.openBox<Map>(ApiUrl.productsBox);
      await box.put(model.productId, model.toMap());
      return;
    } catch (e) {
      logger.e(e);
      throw ServerException();
    }
  }
}
