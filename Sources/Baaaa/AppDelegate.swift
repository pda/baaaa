import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var sheep: [SheepController] = []
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        spawnSheep()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "🐑"

        let menu = NSMenu()

        let addItem = NSMenuItem(title: "New Sheep", action: #selector(addSheep), keyEquivalent: "n")
        addItem.target = self
        menu.addItem(addItem)

        let removeItem = NSMenuItem(title: "Remove All", action: #selector(removeAll), keyEquivalent: "r")
        removeItem.target = self
        menu.addItem(removeItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "About Baaaa", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
    }

    @objc private func addSheep() { spawnSheep() }

    @objc private func removeAll() {
        sheep.forEach { $0.stop() }
        sheep.removeAll()
        spawnSheep()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Baaaa 🐑"
        alert.informativeText = """
        A modern macOS desktop pet that walks around your screen and \
        falls onto the tops of windows.

        Sprite art is from the eSheep project by Adriano Petrucci, \
        derived from the classic Windows desktop pet of the same name.
        """
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func spawnSheep() {
        guard let screen = NSScreen.main else { return }
        let controller = SheepController(screen: screen)
        sheep.append(controller)
        controller.start()
    }
}
