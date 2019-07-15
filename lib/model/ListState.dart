class ListState{
  final _value;
  const ListState._internal(this._value);
  toString() => 'Enum.$_value';

  static const INPROCESS = const ListState._internal('INPROCESS');
  static const FINISHED = const ListState._internal('FINISHED');
  static const BUYING = const ListState._internal('BUYING');
  static const DISPACHED = const ListState._internal('DISPACHED');
  static const UNKNOWN = const ListState._internal('UNKNOWN');

  static ListState fromString(String s){
    switch (s){
      case 'INPROCESS':
        return ListState.INPROCESS;
        break;
      case 'FINISHED':
        return ListState.FINISHED;
        break;
      case 'BUYING':
        return ListState.BUYING;
        break;
      case 'DISPACHED':
        return ListState.DISPACHED;
        break;
      default:
        return ListState.UNKNOWN;
    }
  }

  static String stateToString(ListState state) {
    switch (state){
      case ListState.INPROCESS:
        return 'INPROCESS';
        break;
      case ListState.FINISHED:
        return 'FINISHED';
        break;
      case ListState.BUYING:
        return 'BUYING';
        break;
      case ListState.DISPACHED:
        return 'DISPACHED';
        break;
      default:
        return 'UNKNOWN';
    }
  }
}

