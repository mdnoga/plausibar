import SwiftUI

struct NotchShape: Shape {
    var notchWidth: CGFloat
    var notchHeight: CGFloat
    var bottomCornerRadius: CGFloat = 12
    var notchCornerRadius: CGFloat = 10

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(notchHeight, bottomCornerRadius) }
        set {
            notchHeight = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let nl = (w - notchWidth) / 2
        let nr = nl + notchWidth
        let ncr = min(notchCornerRadius, notchHeight / 2, notchWidth / 2)
        let bcr = min(bottomCornerRadius, h / 2, w / 2)

        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: nl - ncr, y: 0))
        p.addQuadCurve(to: CGPoint(x: nl, y: ncr), control: CGPoint(x: nl, y: 0))
        p.addLine(to: CGPoint(x: nl, y: notchHeight - ncr))
        p.addQuadCurve(to: CGPoint(x: nl + ncr, y: notchHeight), control: CGPoint(x: nl, y: notchHeight))
        p.addLine(to: CGPoint(x: nr - ncr, y: notchHeight))
        p.addQuadCurve(to: CGPoint(x: nr, y: notchHeight - ncr), control: CGPoint(x: nr, y: notchHeight))
        p.addLine(to: CGPoint(x: nr, y: ncr))
        p.addQuadCurve(to: CGPoint(x: nr + ncr, y: 0), control: CGPoint(x: nr, y: 0))
        p.addLine(to: CGPoint(x: w, y: 0))
        p.addLine(to: CGPoint(x: w, y: h - bcr))
        p.addQuadCurve(to: CGPoint(x: w - bcr, y: h), control: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: bcr, y: h))
        p.addQuadCurve(to: CGPoint(x: 0, y: h - bcr), control: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}
