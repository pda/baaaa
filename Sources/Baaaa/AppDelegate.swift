import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// At 30 Hz, spawn a fresh grass patch every 2-5 minutes.
    private static let grassSpawnRange = 3_600...9_000
    /// If Dock geometry is unavailable, retry after 30-60 seconds.
    private static let grassRetryRange = 900...1_800

    private var sheep: [SheepController] = []
    private var grass: [GrassPatchController] = []
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var grassSpawnCountdown = Int.random(in: grassSpawnRange)

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        spawnSheep()
        startTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
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
        grass.forEach { $0.stop() }
        grass.removeAll()
        grassSpawnCountdown = Int.random(in: Self.grassSpawnRange)
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
        alert.icon = NSApp.applicationIconImage
        alert.runModal()
    }

    private func spawnSheep() {
        guard let screen = NSScreen.main else { return }
        let controller = SheepController(screen: screen) { [weak self] sheepID in
            self?.sheep.compactMap { other in
                guard other.id != sheepID else { return nil }
                return other.awarenessObservation
            } ?? []
        } nearbyGrass: { [weak self] in
            self?.grass.map(\.observation) ?? []
        } claimGrass: { [weak self] grassID in
            self?.claimGrass(id: grassID) ?? false
        } releaseGrass: { [weak self] grassID in
            self?.releaseGrass(id: grassID)
        } consumeGrass: { [weak self] grassID in
            self?.removeGrass(id: grassID)
        }
        sheep.append(controller)
        controller.start()
    }

    private func startTimer() {
        let interval = 1.0 / SheepController.tickHz
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.stepFlock()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stepFlock() {
        guard let screen = NSScreen.main else { return }
        maybeSpawnGrass(on: screen)
        let snapshot = WindowSurfaceCache.current(
            frontmostPID: FrontmostApp.shared.pid,
            screen: screen
        )
        sheep.forEach { $0.step(windowSurfaceSnapshot: snapshot) }
    }

    private func maybeSpawnGrass(on screen: NSScreen) {
        guard grass.isEmpty else { return }
        if grassSpawnCountdown > 0 {
            grassSpawnCountdown -= 1
            return
        }

        guard let patch = GrassPatchController(screen: screen) else {
            grassSpawnCountdown = Int.random(in: Self.grassRetryRange)
            return
        }

        grass.append(patch)
        patch.start()
    }

    private func removeGrass(id: Int) {
        guard let index = grass.firstIndex(where: { $0.id == id }) else { return }
        grass[index].stop()
        grass.remove(at: index)
        grassSpawnCountdown = Int.random(in: Self.grassSpawnRange)
    }

    private func claimGrass(id: Int) -> Bool {
        guard let index = grass.firstIndex(where: { $0.id == id }) else { return false }
        return grass[index].claim()
    }

    private func releaseGrass(id: Int) {
        guard let index = grass.firstIndex(where: { $0.id == id }) else { return }
        grass[index].releaseClaim()
    }
}
