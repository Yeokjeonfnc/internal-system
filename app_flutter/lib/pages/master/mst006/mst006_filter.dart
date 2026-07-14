class OwnerUserFilter {
  const OwnerUserFilter({this.keyword = ''});

  final String keyword;

  OwnerUserFilter copyWith({String? keyword}) {
    return OwnerUserFilter(keyword: keyword ?? this.keyword);
  }
}
