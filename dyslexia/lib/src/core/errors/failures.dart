import 'package:equatable/equatable.dart';

class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {
  const ServerFailure();
}

class CacheFailure extends Failure {
  const CacheFailure();
}

class EmptyFailure extends Failure {
  const EmptyFailure();
}

class CredentialFailure extends Failure {
  const CredentialFailure();
}

class DuplicateEmailFailure extends Failure {
  const DuplicateEmailFailure();
}

class PasswordNotMatchFailure extends Failure {
  const PasswordNotMatchFailure();
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure();
}

class InvalidPasswordFailure extends Failure {
  const InvalidPasswordFailure();
}

class FilePickerFailure extends Failure {
  const FilePickerFailure();
}

class OcrFailure extends Failure {
  const OcrFailure();
}

class TextExtractionFailure extends Failure {
  const TextExtractionFailure();
}

class InvalidAccountNumberFailure extends Failure {
  const InvalidAccountNumberFailure();
}

class NetworkFailure extends Failure {
  const NetworkFailure();
}
