part of 'scan_bloc.dart';

abstract class ScanEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartScanEvent extends ScanEvent {}
