import UIKit

extension UIView {
    func autolayout() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    
    func fillSuperview(_ edgeInsets: NSDirectionalEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview!.topAnchor, constant: edgeInsets.top),
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor, constant: edgeInsets.leading),
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor, constant: -edgeInsets.bottom),
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor, constant: -edgeInsets.trailing)]
        )
    }
}
