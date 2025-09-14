//
//  ContainerCore.swift
//  DiContainer
//
//  Created by Wonja Suh on 3/19/25.
//

import Foundation

// MARK: - Container Core Implementation

/// ## 개요
///
/// `Container`는 여러 개의 `Module` 인스턴스를 수집하고 일괄 등록할 수 있는
/// Swift Concurrency 기반의 액터입니다. 이 컨테이너는 대규모 의존성 그래프를
/// 효율적으로 관리하고 병렬 처리를 통해 성능을 최적화합니다.
///
/// ## 핵심 특징
///
/// ### ⚡ 고성능 병렬 처리
/// - **Task Group 활용**: 모든 모듈의 등록을 동시에 병렬 실행
/// - **스냅샷 기반**: 내부 배열을 복사하여 actor hop 최소화
/// - **비동기 안전**: Swift Concurrency 패턴으로 스레드 안전성 보장
///
/// ### 🏗️ 배치 등록 시스템
/// - **모듈 수집**: 여러 모듈을 먼저 수집한 후 한 번에 등록
/// - **지연 실행**: `build()` 호출 시점까지 실제 등록 지연
/// - **원자적 처리**: 모든 모듈이 함께 등록되거나 실패
///
/// ### 🔒 동시성 안전성
/// - **Actor 보호**: 내부 상태(`modules`)가 데이터 경쟁으로부터 안전
/// - **순서 독립**: 모듈 등록 순서와 무관하게 동작
/// - **메모리 안전**: 약한 참조 없이도 안전한 메모리 관리
public actor Container {
    // MARK: - 저장 프로퍼티

    /// 등록된 모듈(Module) 인스턴스들을 저장하는 내부 배열.
    internal var modules: [Module] = []

    // MARK: - 초기화

    /// 기본 초기화 메서드.
    /// - 설명: 인스턴스 생성 시 `modules` 배열은 빈 상태로 시작됩니다.
    public init() {}

    // MARK: - 모듈 등록

    /// 모듈을 컨테이너에 추가하여 나중에 일괄 등록할 수 있도록 준비합니다.
    ///
    /// 이 메서드는 즉시 모듈을 DI 컨테이너에 등록하지 않고, 내부 배열에 저장만 합니다.
    /// 실제 등록은 `build()` 메서드 호출 시에 모든 모듈이 병렬로 처리됩니다.
    ///
    /// - Parameter module: 등록 예약할 `Module` 인스턴스
    /// - Returns: 체이닝을 위한 현재 `Container` 인스턴스
    ///
    /// - Note: 이 메서드는 실제 등록을 수행하지 않고 모듈을 큐에 추가만 합니다.
    /// - Important: 동일한 타입의 모듈을 여러 번 등록하면 마지막 등록이 우선됩니다.
    /// - SeeAlso: `build()` - 실제 모든 모듈을 병렬 등록하는 메서드
    @discardableResult
    public func register(_ module: Module) -> Self {
        modules.append(module)
        return self
    }

    /// Trailing closure를 처리할 때 사용되는 메서드입니다.
    ///
    /// - Parameter block: 호출 즉시 실행할 클로저. 이 클로저 내부에서 추가 설정을 수행할 수 있습니다.
    /// - Returns: 현재 `Container` 인스턴스(Self). 메서드 체이닝(Fluent API) 방식으로 연쇄 호출이 가능합니다.
    @discardableResult
    public func callAsFunction(_ block: () -> Void) -> Self {
        block()
        return self
    }

    // MARK: - 상태 조회

    /// 현재 등록 대기 중인 모듈의 개수를 반환합니다.
    /// - Returns: 대기 중인 모듈 개수
    public var moduleCount: Int {
        modules.count
    }

    /// 컨테이너가 비어있는지 확인합니다.
    /// - Returns: 등록된 모듈이 없으면 true
    public var isEmpty: Bool {
        modules.isEmpty
    }

    /// 등록된 모듈들의 타입 이름을 반환합니다 (디버깅용).
    /// - Returns: 모듈 타입 이름 배열
    public func getModuleTypeNames() -> [String] {
        modules.map { String(describing: type(of: $0)) }
    }
}