import Foundation

extension Double {
    static let durationStringFormatter: DateComponentsFormatter = {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()

    func toDurationString() -> String {
        if (self.isNaN) {
            return ""
        }
        if (self.isInfinite) {
            return ""
        }
        return Double.durationStringFormatter.string(from: Double(self)) ?? ""
    }
}
