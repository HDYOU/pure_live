

import 'string_extension.dart';
import 'list_extension.dart';

extension ObjectExtension on Object? {
  bool get isNull => this == null;
  bool get isNullOrEmpty => (){
    if(this == null) return true;
    if(this is String){
      return StringExtension(this as String).isNullOrEmpty;
    }
    if(this is List){
      return ListExtension(this as List).isNullOrEmpty;
    }
    if(this is Map){
      return (this as Map).keys.isEmpty;
    }
    if(this is Set){
      return (this as Set).isEmpty;
    }


    return false;
  }();

  bool get isNotNullOrEmpty => !isNullOrEmpty;

}