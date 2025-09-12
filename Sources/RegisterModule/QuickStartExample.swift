//
//  QuickStartExample.swift
//  DiContainer
//
//  Created by Wonja Suh on 3/24/25.
//

import Foundation
import LogMacro

/// 빠른 시작 가이드 및 예제
/// 
/// ## 사용법:
/// 
/// 1. 앱 시작 시 (AppDelegate 또는 App.swift):
/// ```swift
/// // 의존성 등록
/// AutoRegister.add(BookListInterface.self) { BookListRepositoryImpl() }
/// AutoRegister.add(UserServiceInterface.self) { UserServiceImpl() }
/// ```
///
/// 2. 어디서든 사용:
/// ```swift
/// @ContainerRegister(\.bookListInterface)
/// private var repository: BookListInterface
///
/// // 또는
/// let repository = ContainerRegister(\.bookListInterface).wrappedValue
/// ```
///
/// ## 권장 패턴:
/// - Interface 접미사를 가진 프로토콜 사용
/// - Impl 접미사를 가진 구현체 사용
/// - 앱 시작 시 한번에 모든 의존성 등록

public enum QuickStartGuide {
    
    /// 앱 시작 시 호출할 의존성 등록 예제
    /// 사용자는 이것을 참고해서 자신의 타입들을 등록하면 됩니다.
    public static func registerCommonDependencies() {
        #logInfo("📝 [QuickStart] 이것은 예제입니다. 사용자의 실제 타입으로 바꿔주세요:")
        
        // 방법 1: 개별 등록
        #logInfo("📝 [QuickStart] AutoRegister.add(YourInterface.self) { YourImplementation() }")
        
        // 방법 2: 병렬 일괄 등록 (권장)
        #logInfo("📝 [QuickStart] AutoRegister.addMany { ... }")
        
        // 실제 사용 예시 (주석 해제해서 사용):
        /*
        AutoRegister.addMany {
            Registration(BookListInterface.self) { BookListRepositoryImpl() }
            Registration(UserServiceInterface.self) { UserServiceImpl() }
            Registration(NetworkInterface.self) { NetworkServiceImpl() }
        }
        */
        
        // 또는 개별 등록:
        // AutoRegister.add(BookListInterface.self) { BookListRepositoryImpl() }
        // AutoRegister.add(UserServiceInterface.self) { UserServiceImpl() }
    }
}