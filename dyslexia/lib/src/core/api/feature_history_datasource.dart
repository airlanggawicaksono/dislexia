import 'api_helper.dart';
import 'api_url.dart';

class FeatureHistoryItem {
  final String id;
  final String inputText;
  final String outputText;
  final DateTime createdAt;
  final String feature;

  const FeatureHistoryItem({
    required this.id,
    required this.inputText,
    required this.outputText,
    required this.createdAt,
    required this.feature,
  });

  factory FeatureHistoryItem.fromJson(Map<String, dynamic> json) =>
      FeatureHistoryItem(
        id: json['id'] as String,
        inputText: json['input_text'] as String? ?? '',
        outputText: json['output_text'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        feature: json['feature'] as String? ?? '',
      );
}

class FeatureHistoryDatasource {
  final ApiHelper _api;
  const FeatureHistoryDatasource(this._api);

  Future<List<FeatureHistoryItem>> getHistory({String? feature}) async {
    final qp = <String, dynamic>{};
    if (feature != null) qp['feature'] = feature;
    final res = await _api.execute(
      method: Method.get,
      url: '${ApiUrl.baseUrl}/me/history',
      queryParameters: qp,
    );
    final items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return items.map(FeatureHistoryItem.fromJson).toList();
  }
}
