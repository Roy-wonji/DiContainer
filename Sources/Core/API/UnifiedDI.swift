//
//  SimplifiedDI.swift
//  DiContainer
//
//  Created by Wonji Suh on 2024.
//  Copyright © 2024 Wonji Suh. All rights reserved.
//

import Foundation
import LogMacro

// MARK: - Simplified DI API

/// ## 개요
///
/// `UnifiedDI`는 현대적이고 직관적인 의존성 주입 API입니다.
/// 복잡한 기능들을 제거하고 핵심 기능에만 집중하여 이해하기 쉽고 사용하기 간편합니다.
///
/// ## 설계 철학
/// - **단순함이 최고**: 복잡한 기능보다 명확한 API
/// - **타입 안전성**: 컴파일 타임에 모든 오류 검증
/// - **직관적 사용**: 코드만 봐도 이해할 수 있는 API
///
/// ## 기본 사용법
/// ```swift
/// // 1. 등록하고 즉시 사용
/// let repository = UnifiedDI.register(UserRepository.self) {
///     UserRepositoryImpl()
/// }
///
/// // 2. 나중에 조회
/// let service = UnifiedDI.resolve(UserService.self)
///
/// // 3. 필수 의존성 (실패 시 크래시)
/// let logger = UnifiedDI.requireResolve(Logger.self)
/// ```
public enum UnifiedDI {
  
  // MARK: - Core Registration API
  
  /// 의존성을 등록하고 즉시 생성된 인스턴스를 반환합니다 (권장 방식)
  ///
  /// 가장 직관적인 의존성 등록 방법입니다.
  /// 팩토리를 즉시 실행하여 인스턴스를 생성하고, 컨테이너에 등록한 후 반환합니다.
  ///
  /// - Parameters:
  ///   - type: 등록할 타입
  ///   - factory: 인스턴스를 생성하는 클로저
  /// - Returns: 생성된 인스턴스
  ///
  /// ### 사용 예시:
  /// ```swift
  /// let repository = UnifiedDI.register(UserRepository.self) {
  ///     UserRepositoryImpl()
  /// }
  /// // repository를 바로 사용 가능
  /// ```
  public static func register<T>(
    _ type: T.Type,
    factory: @escaping @Sendable () -> T
  ) -> T where T: Sendable {
    let instance = factory()
    DependencyContainer.live.register(type, instance: instance)
    return instance
  }
  
  // MARK: - Async Registration (DIActor-based)
  
  /// DIActor를 사용한 비동기 의존성 등록 (권장)
  ///
  /// Actor 기반의 thread-safe한 의존성 등록을 제공합니다.
  /// 기존 동기 API보다 더 안전하고 확장 가능합니다.
  ///
  /// ### 사용 예시:
  /// ```swift
  /// Task {
  ///     let releaseHandler = await UnifiedDI.registerAsync(UserService.self) {
  ///         UserServiceImpl()
  ///     }
  ///     // 필요시 나중에 해제: await releaseHandler()
  /// }
  /// ```
  @discardableResult
  public static func registerAsync<T>(
    _ type: T.Type,
    factory: @escaping @Sendable () -> T
  ) async -> @Sendable () async -> Void where T: Sendable {
    return await DIActorGlobalAPI.register(type, factory: factory)
  }
  
  /// KeyPath를 사용한 타입 안전한 등록 (UnifiedDI.register(\.keyPath) 스타일)
  ///
  /// DependencyContainer의 KeyPath를 사용하여 더욱 타입 안전하게 등록합니다.
  ///
  /// ### 사용 예시:
  /// ```swift
  /// let repository = UnifiedDI.register(\.productInterface) {
  ///     ProductRepositoryImpl()
  /// }
  /// ```
  @discardableResult
  public static func register<T>(
    _ keyPath: KeyPath<DependencyContainer, T?>,
    factory: @escaping @Sendable () -> T
  ) -> T where T: Sendable {
    let instance = factory()
    // KeyPath를 통한 타입 추론으로 T.self를 등록
    DependencyContainer.live.register(T.self, instance: instance)
    return instance
  }
  
  
  // MARK: - Core Resolution API
  
  /// 등록된 의존성을 조회합니다 (안전한 방법)
  ///
  /// 의존성이 등록되지 않은 경우 nil을 반환하므로 크래시 없이 안전하게 처리할 수 있습니다.
  /// 권장하는 안전한 의존성 해결 방법입니다.
  ///
  /// - Parameter type: 조회할 타입
  /// - Returns: 해결된 인스턴스 (없으면 nil)
  ///
  /// ### 사용 예시:
  /// ```swift
  /// if let service = UnifiedDI.resolve(UserService.self) {
  ///     // 서비스 사용
  /// } else {
  ///     // 대체 로직 수행
  /// }
  /// ```
  public static func resolve<T>(_ type: T.Type) -> T? {
    return DependencyContainer.live.resolve(type)
  }
  
  /// KeyPath를 사용하여 의존성을 조회합니다
  ///
  /// - Parameter keyPath: DependencyContainer 내의 KeyPath
  /// - Returns: 해결된 인스턴스 (없으면 nil)
  public static func resolve<T>(_ keyPath: KeyPath<DependencyContainer, T?>) -> T? {
    return DependencyContainer.live[keyPath: keyPath]
  }
  
  // MARK: - Async Resolution (DIActor-based)
  
  /// DIActor를 사용한 비동기 의존성 조회 (권장)
  ///
  /// Actor 기반의 thread-safe한 의존성 해결을 제공합니다.
  /// 기존 동기 API보다 더 안전하고 성능이 우수합니다.
  ///
  /// ### 사용 예시:
  /// ```swift
  /// Task {
  ///     if let service = await UnifiedDI.resolveAsync(UserService.self) {
  ///         // 서비스 사용
  ///     }
  /// }
  /// ```
  public static func resolveAsync<T>(_ type: T.Type) async -> T? where T: Sendable {
    return await DIActorGlobalAPI.resolve(type)
  }
  
  /// DIActor를 사용한 필수 의존성 조회 (실패 시 예외 발생)
  ///
  /// 반드시 등록되어 있어야 하는 의존성을 비동기적으로 조회합니다.
  /// 등록되지 않은 경우 DIError를 throw합니다.
  public static func requireResolveAsync<T>(_ type: T.Type) async throws -> T where T: Sendable {
    return try await DIActorGlobalAPI.resolveThrows(type)
  }
  
  /// 필수 의존성을 조회합니다 (실패 시 명확한 에러 메시지와 함께 크래시)
  ///
  /// 반드시 등록되어 있어야 하는 의존성을 조회할 때 사용합니다.
  /// 등록되지 않은 경우 개발자 친화적인 에러 메시지와 함께 앱이 종료됩니다.
  ///
  /// - Parameter type: 조회할 타입
  /// - Returns: 해결된 인스턴스 (항상 성공)
  ///
  /// ### ⚠️ 주의사항:
  /// 프로덕션 환경에서는 `resolve(_:)` 사용을 권장합니다.
  ///
  /// ### 사용 예시:
  /// ```swift
  /// let logger = UnifiedDI.requireResolve(Logger.self)
  /// // logger는 항상 유효한 인스턴스
  /// ```
  public static func requireResolve<T>(_ type: T.Type) -> T {
    
    guard let resolved = DependencyContainer.live.resolve(type) else {
      let typeName = String(describing: type)
      
      // 프로덕션에서는 더 안전한 처리
#if DEBUG
      fatalError("""
            🚨 [DI] 필수 의존성을 찾을 수 없습니다!
            
            타입: \(typeName)
            
            💡 해결 방법:
               UnifiedDI.register(\(typeName).self) { YourImplementation() }
            
            🔍 등록이 해결보다 먼저 수행되었는지 확인해주세요.
            
            """)
#else
      // 프로덕션에서는 에러 로깅 후 기본 인스턴스 시도
      Log.error("🚨 [DI] Critical: Required dependency \(typeName) not found!")
      
      // 마지막 수단으로 기본 초기화 시도
      if let defaultInstance = Self.tryCreateDefaultInstance(for: type) {
        Log.warning("🔄 [DI] Using default instance for \(typeName)")
        return defaultInstance
      }
      
      // 그래도 실패하면 크래시하되, 더 간단한 메시지로
      fatalError("[DI] Critical dependency missing: \(typeName)")
#endif
    }
    return resolved
  }
  
  
  /// 의존성을 조회하거나 기본값을 반환합니다 (항상 성공)
  ///
  /// 의존성이 없어도 항상 성공하는 안전한 해결 방법입니다.
  /// 기본 구현체나 Mock 객체를 제공할 때 유용합니다.
  ///
  /// - Parameters:
  ///   - type: 조회할 타입
  ///   - defaultValue: 해결 실패 시 사용할 기본값
  /// - Returns: 해결된 인스턴스 또는 기본값
  ///
  /// ### 사용 예시:
  /// ```swift
  /// let logger = UnifiedDI.resolve(Logger.self, default: ConsoleLogger())
  /// // logger는 항상 유효한 인스턴스
  /// ```
  public static func resolve<T>(_ type: T.Type, default defaultValue: @autoclosure () -> T) -> T {
    return DependencyContainer.live.resolve(type) ?? defaultValue()
  }
  
  
  
  // MARK: - Management API
  
  /// 등록된 의존성을 해제합니다
  ///
  /// 특정 타입의 의존성을 컨테이너에서 제거합니다.
  /// 주로 테스트나 메모리 정리 시 사용합니다.
  ///
  /// - Parameter type: 해제할 타입
  ///
  /// ### 사용 예시:
  /// ```swift
  /// UnifiedDI.release(UserService.self)
  /// // 이후 resolve 시 nil 반환
  /// ```
  public static func release<T>(_ type: T.Type) {
    DependencyContainer.live.release(type)
  }
  
  /// 모든 등록된 의존성을 해제합니다 (테스트용)
  ///
  /// 주로 테스트 환경에서 각 테스트 간 격리를 위해 사용합니다.
  /// 프로덕션에서는 사용을 권장하지 않습니다.
  ///
  /// ### ⚠️ 주의사항:
  /// 메인 스레드에서만 호출해야 합니다.
  ///
  /// ### 사용 예시:
  /// ```swift
  /// // 테스트 setUp에서
  /// override func setUp() {
  ///     super.setUp()
  ///     UnifiedDI.releaseAll()
  /// }
  /// ```
  @MainActor
  public static func releaseAll() {
    DependencyContainer.live = DependencyContainer()
  }
}

// MARK: - Advanced Features (별도 네임스페이스)

/// 고급 기능들을 위한 네임스페이스
///
/// 일반적인 사용에서는 필요하지 않은 고급 기능들을 별도로 분리했습니다.
/// 설계 철학에 따라 핵심 기능과 분리하여 복잡도를 줄였습니다.
public extension UnifiedDI {
  
  /// 조건부 등록을 위한 네임스페이스
  enum Conditional {
    /// 조건에 따라 다른 구현체를 등록합니다
    ///
    /// - Parameters:
    ///   - type: 등록할 타입
    ///   - condition: 등록 조건
    ///   - factory: 조건이 true일 때 사용할 팩토리
    ///   - fallback: 조건이 false일 때 사용할 팩토리
    /// - Returns: 생성된 인스턴스
    @discardableResult
    public static func registerIf<T>(
      _ type: T.Type,
      condition: Bool,
      factory: @escaping @Sendable () -> T,
      fallback: @escaping @Sendable () -> T
    ) -> T where T: Sendable {
      if condition {
        return UnifiedDI.register(type, factory: factory)
      } else {
        return UnifiedDI.register(type, factory: fallback)
      }
    }
  }
}


// MARK: - Auto DI Features

/// 자동 의존성 주입 기능 확장
public extension UnifiedDI {
  
  /// 🚀 자동 생성된 의존성 그래프를 시각화합니다
  ///
  /// 별도 설정 없이 자동으로 수집된 의존성 관계를 확인할 수 있습니다.
  ///
  /// ### 사용 예시:
  /// ```swift
  /// // 현재까지 자동 수집된 의존성 그래프 출력
  /// print(UnifiedDI.autoGraph)
  /// ```
  static func autoGraph() -> String {
    DIContainer.shared.getAutoGeneratedGraph()
  }
  
  /// ⚡ 자동 최적화된 타입들을 반환합니다
  ///
  /// 사용 패턴을 분석하여 자동으로 성능 최적화가 적용된 타입들입니다.
  static func optimizedTypes() -> Set<String> {
    DIContainer.shared.getOptimizedTypes()
  }
  
  /// ⚠️ 자동 감지된 순환 의존성을 반환합니다
  ///
  /// 의존성 등록/해결 과정에서 자동으로 감지된 순환 의존성입니다.
  static func circularDependencies() -> Set<String> {
    DIContainer.shared.getDetectedCircularDependencies()
  }
  
  /// 📊 자동 수집된 성능 통계를 반환합니다
  ///
  /// 각 타입의 사용 빈도가 자동으로 추적됩니다.
  static func stats() -> [String: Int] {
    DIContainer.shared.getUsageStatistics()
  }
  
  /// 🔍 특정 타입이 자동 최적화되었는지 확인합니다
  ///
  /// - Parameter type: 확인할 타입
  /// - Returns: 최적화 여부
  static func isOptimized<T>(_ type: T.Type) -> Bool {
    DIContainer.shared.isAutoOptimized(type)
  }
  
  /// ⚙️ 자동 최적화 기능을 제어합니다
  ///
  /// - Parameter enabled: 활성화 여부 (기본값: true)
  static func setAutoOptimization(_ enabled: Bool) {
    DIContainer.shared.setAutoOptimization(enabled)
  }
  
  /// 🧹 자동 수집된 통계를 초기화합니다
  static func resetStats() {
    DIContainer.shared.resetAutoStats()
  }
  
  /// 📋 자동 로깅 레벨을 설정합니다
  ///
  /// - Parameter level: 로깅 레벨
  ///   - `.all`: 모든 로그 출력 (기본값)
  ///   - `.registration`: 등록만 로깅
  ///   - `.optimization`: 최적화만 로깅
  ///   - `.errors`: 에러만 로깅
  ///   - `.off`: 로깅 끄기
  static func setLogLevel(_ level: LogLevel) {
    AutoDIOptimizer.shared.setLogLevel(level)
  }
  
  /// 📋 현재 로깅 레벨을 반환합니다
  static func getLogLevel() async -> LogLevel {
    AutoDIOptimizer.shared.getCurrentLogLevel()
  }
  
  /// 현재 로깅 레벨(동기 접근용)
  static var logLevel: LogLevel {
    AutoDIOptimizer.shared.getCurrentLogLevel()
  }
  
  /// 🎯 자동 Actor 최적화 제안을 반환합니다
  ///
  /// 자동으로 수집된 Actor hop 패턴과 성능 분석을 바탕으로 최적화 제안을 제공합니다.
  static var actorOptimizations: [String: ActorOptimization] {
    get async {
      AutoDIOptimizer.shared.getActorOptimizationSuggestions()
    }
  }
  
  /// 🔒 자동 감지된 타입 안전성 이슈를 반환합니다
  ///
  /// 런타임에서 자동으로 감지된 타입 안전성 문제들과 권장사항을 제공합니다.
  static var typeSafetyIssues: [String: TypeSafetyIssue] {
    get async {
      AutoDIOptimizer.shared.getDetectedTypeSafetyIssues()
    }
  }
  
  /// 🛠️ 자동으로 수정된 타입들을 반환합니다
  ///
  /// 타입 안전성 검사에서 자동으로 수정 처리된 타입들의 목록입니다.
  static var autoFixedTypes: Set<String> {
    get async {
      AutoDIOptimizer.shared.getDetectedAutoFixedTypes()
    }
  }
  
  /// ⚡ Actor hop 통계를 반환합니다
  ///
  /// 각 타입별로 발생한 Actor hop 횟수를 추적한 통계입니다.
  static var actorHopStats: [String: Int] {
    get async {
      AutoDIOptimizer.shared.getActorHopStats()
    }
  }
  
  /// 📊 비동기 성능 통계를 반환합니다
  ///
  /// 각 타입별 평균 비동기 해결 시간 (밀리초)을 제공합니다.
  static var asyncPerformanceStats: [String: Double] {
    get async {
      AutoDIOptimizer.shared.getAsyncPerformanceStats()
    }
  }
  
  // MARK: - Advanced Configuration
  
  /// 최적화 설정을 간편하게 조정합니다
  /// - Parameters:
  ///   - debounceMs: 디바운스 간격 (50-500ms, 기본값: 100ms)
  ///   - threshold: 자주 사용되는 타입 임계값 (5-100회, 기본값: 10회)
  ///   - realTimeUpdate: 실시간 그래프 업데이트 여부 (기본값: true)
  static func configureOptimization(
    debounceMs: Int = 100,
    threshold: Int = 10,
    realTimeUpdate: Bool = true
  ) {
    // 간단한 설정 업데이트
    AutoDIOptimizer.shared.updateConfig("debounce: \(debounceMs), threshold: \(threshold), realTime: \(realTimeUpdate)")
  }
  
  /// 그래프 변경 히스토리를 가져옵니다
  /// - Parameter limit: 최대 반환 개수 (기본값: 10)
  /// - Returns: 최근 변경 히스토리
  static func getGraphChanges(limit: Int = 10) async -> [(timestamp: Date, changes: [String: NodeChangeType])] {
    return  AutoDIOptimizer.shared.getRecentGraphChanges(limit: limit)
  }
}


// MARK: - 🔍 간단한 모니터링 API

public extension UnifiedDI {
  /// 📊 현재 등록된 모든 모듈 보기 (최적화 정보 포함)
  static func showModules() async {
    await AutoDIOptimizer.shared.showAll()
  }
  
  /// 📈 간단한 요약 정보
  static func summary() async -> String {
    return await AutoMonitor.shared.getSummary()
  }
  
  /// 🔗 특정 모듈의 의존성 보기
  static func showDependencies(for module: String) async -> [String] {
    return await AutoMonitor.shared.showDependenciesFor(module: module)
  }
  
  /// ⚡ 최적화 제안 보기
  static func getOptimizationTips() -> [String] {
    return AutoDIOptimizer.shared.getOptimizationSuggestions()
  }
  
  /// 📊 자주 사용되는 타입 TOP 5
  static func getTopUsedTypes() -> [String] {
    return AutoDIOptimizer.shared.getTopUsedTypes()
  }
  
  /// 🔧 최적화 기능 켜기/끄기
  static func enableOptimization(_ enabled: Bool = true) {
    AutoDIOptimizer.shared.setOptimizationEnabled(enabled)
  }
  
  /// 🧹 모니터링 초기화
  static func resetMonitoring() async {
    AutoDIOptimizer.shared.reset()
    await AutoMonitor.shared.reset()
  }
}

// MARK: - Legacy Compatibility
