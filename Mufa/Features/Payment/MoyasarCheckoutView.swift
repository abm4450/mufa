import SwiftUI
import WebKit

struct MoyasarConfig: Encodable {
    let amount: Int
    let currency: String
    let description: String
    let publishable_api_key: String
    let callback_url: String
    let metadata: [String: String]
}

struct MoyasarCheckoutView: UIViewControllerRepresentable {
    let config: MoyasarConfig
    let onReturn: (_ orderId: Int?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReturn: onReturn)
    }

    func makeUIViewController(context: Context) -> MoyasarWebViewController {
        let vc = MoyasarWebViewController()
        vc.coordinator = context.coordinator
        vc.loadMoyasar(config: config)
        return vc
    }

    func updateUIViewController(_ uiViewController: MoyasarWebViewController, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onReturn: (_ orderId: Int?) -> Void
        init(onReturn: @escaping (_ orderId: Int?) -> Void) { self.onReturn = onReturn }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            if Self.isMufaReturn(url) {
                decisionHandler(.cancel)
                onReturn(Self.parseOrderId(url))
                return
            }
            decisionHandler(.allow)
        }

        private static func isMufaReturn(_ url: URL) -> Bool {
            let s = url.absoluteString
            return s.contains("moyasar_return=1") && s.contains("mufa_order_id=")
        }

        private static func parseOrderId(_ url: URL) -> Int? {
            guard let c = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let items = c.queryItems else { return nil }
            let raw = items.first { $0.name == "mufa_order_id" }?.value
            return raw.flatMap { Int($0) }
        }
    }
}

final class MoyasarWebViewController: UIViewController {
    weak var coordinator: MoyasarCheckoutView.Coordinator?
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = coordinator
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func loadMoyasar(config: MoyasarConfig) {
        let data = try! JSONEncoder().encode(config)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        guard let path = Bundle.main.path(forResource: "moyasar_host", ofType: "html"),
              var html = try? String(contentsOfFile: path, encoding: .utf8) else {
            return
        }
        html = html.replacingOccurrences(of: "__MOYASAR_CONFIG__", with: json)
        webView.loadHTMLString(html, baseURL: nil)
    }
}
