/// 가맹점 계약 상태.
enum StoreStatus { newContract, renewal, transfer }

/// 가맹점 목록·상세 공통 모델. 목업은 `package:app_flutter/core/data/mock/mock_stores.dart`.
class Store {
  const Store({
    required this.no,
    required this.storeName,
    required this.brand,
    required this.storeCode,
    required this.contractStatus,
    required this.ownerName,
    required this.contact,
    required this.address,
    required this.addressDetail,
    required this.contractDate,
    required this.openingDate,
    required this.storeArea,
    required this.businessNumber,
  });

  final int no;
  final String storeName;
  final String brand;
  final String storeCode;
  final StoreStatus contractStatus;
  final String ownerName;
  final String contact;
  final String address;
  final String addressDetail;
  final String contractDate;
  final String openingDate;
  final String storeArea;
  final String businessNumber;
}

/// 문서 탭 한 행. 목업은 `package:app_flutter/core/data/mock/mock_documents.dart`.
class Document {
  const Document({
    required this.fileName,
    required this.modifiedAt,
    required this.modifiedBy,
    required this.attached,
    required this.attachmentBaseDate,
    required this.attachedAt,
  });

  final String fileName;
  final String modifiedAt;
  final String modifiedBy;
  final bool attached;
  final String attachmentBaseDate;
  final String attachedAt;
}

/// 히스토리 탭 한 행. 목업은 `package:app_flutter/core/data/mock/mock_history.dart`.
class HistoryEntry {
  const HistoryEntry({required this.registeredAt, required this.content});

  final String registeredAt;
  final String content;
}
