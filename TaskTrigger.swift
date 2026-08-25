import SwiftUI

// MARK: - 触发条件类型

enum TaskTriggerType: String, CaseIterable, Identifiable {
    case none
    case location
    case specificDate
    case weekdays
    case daysLater

    var id: String { rawValue }

    /// 新建/编辑页面实际展示的可选触发条件
    static var selectableCases: [TaskTriggerType] {
        [.location, .specificDate, .weekdays]
    }

    var label: String {
        switch self {
        case .none: return "无"
        case .location: return "地点"
        case .specificDate: return "具体时间"
        case .weekdays: return "星期"
        case .daysLater: return "N天后"
        }
    }

    var icon: String {
        switch self {
        case .none: return "circle"
        case .location: return "mappin.and.ellipse"
        case .specificDate: return "calendar.badge.clock"
        case .weekdays: return "calendar"
        case .daysLater: return "hourglass"
        }
    }
}

// MARK: - 星期选项

struct WeekdayOption: Identifiable {
    let weekday: Int // Calendar: 1 = Sunday ... 7 = Saturday
    var id: Int { weekday }

    var shortName: String {
        Self.chineseShortName(for: weekday)
    }

    static func chineseShortName(for weekday: Int) -> String {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        return names[weekday - 1]
    }
}

let weekdayOptions: [WeekdayOption] = (1...7).map { WeekdayOption(weekday: $0) }

// MARK: - 触发条件配置

struct TaskTriggerConfig: Equatable {
    var type: TaskTriggerType = .none
    var location: String = ""
    var date: Date = Date()
    var weekdays: Set<Int> = []
    var daysLater: Int = 1

    var weekdayMask: Int32 {
        weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
    }

    static func from(task: TaskEntity) -> TaskTriggerConfig {
        var type = task.wrappedTriggerType
        if type == .daysLater {
            type = .none
        }

        return TaskTriggerConfig(
            type: type,
            location: task.triggerLocation ?? "",
            date: task.triggerDate ?? Date(),
            weekdays: task.triggerWeekdaySet,
            daysLater: Int(task.triggerDaysLater)
        )
    }

    var summary: String {
        switch type {
        case .none:
            return ""
        case .location:
            return location.isEmpty ? "未设置地点" : "到达 \(location)"
        case .specificDate:
            return date.formatted(date: .abbreviated, time: .shortened)
        case .weekdays:
            if weekdays.isEmpty { return "未选择星期" }
            return weekdays.sorted()
                .map { "周\(WeekdayOption.chineseShortName(for: $0))" }
                .joined(separator: "、")
        case .daysLater:
            return "创建后 \(daysLater) 天"
        }
    }
}

// MARK: - 触发条件编辑器

struct TaskTriggerEditor: View {
    @Binding var enabled: Bool
    @Binding var config: TaskTriggerConfig

    private var triggerBinding: Binding<Bool> {
        Binding(
            get: { enabled },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.15)) {
                    enabled = newValue
                }

                if newValue && config.type == .none {
                    config.type = .location
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: triggerBinding) {
                HStack(spacing: 6) {
                    Image(systemName: "switch.2")
                        .font(.system(size: 13))
                    Text("条件触发")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.themeText)
                }
            }
            .tint(.themePrimary)

            if enabled {
                typePicker
                conditionEditor
            } else {
                Text("开启后，满足触发条件的任务才会自动变为正常任务。")
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextMuted)
            }
        }
    }

    private var typePicker: some View {
        HStack(spacing: 8) {
            ForEach(TaskTriggerType.selectableCases) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        config.type = type
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.system(size: 12))
                        Text(type.label)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(config.type == type ? .white : .themeTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(config.type == type ? Color.themePrimary : Color.themeBG)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var conditionEditor: some View {
        switch config.type {
        case .location:
            TextField("输入地点，如 公司 / 家 / 图书馆", text: $config.location)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.themeBG)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.extraSmall)
                        .stroke(Color.themeBorder, lineWidth: 2)
                )

        case .specificDate:
            DatePicker(
                "触发时间",
                selection: $config.date,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(.system(size: 15))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.themeBG)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))

        case .weekdays:
            HStack(spacing: 6) {
                ForEach(weekdayOptions) { option in
                    Button {
                        if config.weekdays.contains(option.weekday) {
                            config.weekdays.remove(option.weekday)
                        } else {
                            config.weekdays.insert(option.weekday)
                        }
                    } label: {
                        Text("周\(option.shortName)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(config.weekdays.contains(option.weekday) ? .white : .themeTextSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                config.weekdays.contains(option.weekday) ? Color.themePrimary : Color.themeBG
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

        default:
            EmptyView()
        }
    }
}
