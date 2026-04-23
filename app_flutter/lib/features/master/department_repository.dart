// 부서 데이터 목업 Repository.

import 'package:app_flutter/features/master/department_model.dart';

/// 현재는 하드코딩된 목업 데이터를 반환한다.
class DepartmentRepository {
  /// 부서 트리 전체를 반환.
  List<Department> all() {
    return _mockDepartments;
  }
}

/// 이미지 기반 목업 데이터.
final _mockDepartments = [
  const Department(
    id: 'root',
    name: '역전F&C',
    manager: '이병윤',
    userCount: 3,
    children: [
      Department(
        id: 'mgmt',
        name: '경영지원본부',
        manager: '임경민',
        userCount: 1,
        parentId: 'root',
        children: [
          Department(
            id: 'debt',
            name: '채무팀',
            manager: '',
            userCount: 3,
            parentId: 'mgmt',
          ),
          Department(
            id: 'hr',
            name: '인사총무팀',
            manager: '',
            userCount: 3,
            parentId: 'mgmt',
          ),
          Department(
            id: 'purchase',
            name: '구매에뉴운영팀',
            manager: '',
            userCount: 4,
            parentId: 'mgmt',
          ),
          Department(
            id: 'marketing',
            name: '마케팅팀',
            manager: '',
            userCount: 3,
            parentId: 'mgmt',
          ),
          Department(
            id: 'interior',
            name: '인테리어팀',
            manager: '',
            userCount: 1,
            parentId: 'mgmt',
          ),
          Department(
            id: 'store_dev',
            name: '점포개발팀',
            manager: '',
            userCount: 6,
            parentId: 'mgmt',
          ),
          Department(
            id: 'it',
            name: 'IT팀',
            manager: '',
            userCount: 3,
            parentId: 'mgmt',
          ),
        ],
      ),
      Department(
        id: 'ops',
        name: '운영본부',
        manager: '정명근',
        userCount: 1,
        parentId: 'root',
      ),
    ],
  ),
];
