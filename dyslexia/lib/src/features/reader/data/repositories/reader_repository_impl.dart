import '../../domain/repositories/reader_repository.dart';
import '../datasources/local_syllabifier_datasource.dart';

class ReaderRepositoryImpl implements ReaderRepository {
  final LocalSyllabifierDatasource _local;

  const ReaderRepositoryImpl(this._local);

  @override
  Future<String> syllabify(String text) async {
    return _local.syllabify(text);
  }
}
