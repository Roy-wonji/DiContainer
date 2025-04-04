//
//  UseCaseModuleFactory.swift
//  DiContainer
//
//  Created by Wonji Suh  on 3/20/25.
//

import Foundation

/// UseCaseModuleFactory는 UseCaseModuleFactoryProtocol을 채택하는 구조체입니다.
/// 이 구조체는 의존성 등록 헬퍼 객체(registerModule)와 Use Case 모듈 생성 클로저 배열(useCaseDefinitions)을 포함합니다.
/// 기본 구현에서는 useCaseDefinitions가 빈 배열을 반환하도록 설정되어 있어,
/// 앱 측에서 extension을 통해 원하는 모듈 정의를 추가하여 재정의할 수 있습니다.
#if swift(>=5.9)
@available(iOS 17.0, *)
public struct UseCaseModuleFactory: UseCaseModuleFactoryProtocol {
    
    /// 의존성 등록을 담당하는 헬퍼 객체입니다.
    /// 이 객체는 Use Case 모듈을 생성할 때 필요한 의존성들을 등록하는 역할을 합니다.
    public let registerModule = RegisterModule()
    
    /// Use Case 모듈을 생성하는 클로저들의 배열입니다.
    /// 각 클로저는 호출 시 Module 인스턴스를 반환합니다.
    /// 기본 구현에서는 빈 배열을 반환하므로, 앱에서는 extension을 통해 이 배열을 재정의하여 사용합니다.
    public var useCaseDefinitions: [() -> Module] {
        return []
    }
    
    /// 기본 생성자입니다.
    /// 별도의 인자 없이 인스턴스를 생성할 수 있으며, 이후 앱 측에서 extension을 통해 useCaseDefinitions를 재정의할 수 있습니다.
    public init() {}
}

#else
public struct UseCaseModuleFactory: UseCaseModuleFactoryProtocol {
    public let registerModule = RegisterModule()
    
    public var useCaseDefinitions: [() -> Module] {
        return []
    }
    
    public init() {}
}
#endif
