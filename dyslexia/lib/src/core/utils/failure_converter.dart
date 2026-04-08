import '../errors/failures.dart';

String mapFailureToMessage(Failure failure) {
  return switch (failure) {
    ServerFailure _ => "Server Failure",
    CacheFailure _ => "Cache Failure",
    EmptyFailure _ => "Empty Failure",
    CredentialFailure _ => "Wrong Email or Password",
    DuplicateEmailFailure _ => "Email already taken",
    PasswordNotMatchFailure _ => "Password not match",
    InvalidEmailFailure _ => "Invalid email format",
    InvalidPasswordFailure _ => "Invalid password format",
    FilePickerFailure _ => "Failed to pick file",
    OcrFailure _ => "Failed to read text from image",
    TextExtractionFailure _ => "Failed to extract text",
  };
}
