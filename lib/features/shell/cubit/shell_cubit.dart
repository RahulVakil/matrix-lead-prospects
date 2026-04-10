import 'package:flutter_bloc/flutter_bloc.dart';

class ShellCubit extends Cubit<int> {
  ShellCubit() : super(0);

  void updateIndex(int index) {
    if (index >= 0 && index <= 4) {
      emit(index);
    }
  }
}
