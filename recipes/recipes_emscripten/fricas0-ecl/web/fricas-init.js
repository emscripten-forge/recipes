self.Module = self.Module || {};
self.Module.preRun = self.Module.preRun || [];

self.Module.preRun.push(function() {
    addRunDependency('fricas_fs_init');

    async function initFS() {
        try {
            try { FS.mkdirTree('/home/web_user'); } catch(e) {}
            const startupScript = `
            ;; Trick FriCAS into skipping the compiler check
            (provide :cmp)
            (provide "cmp")
            
            ;; Mock the missing C package symbol so the Lisp Reader doesn't crash
            (unless (find-package "C") (make-package "C"))
            (intern "BUILD-PROGRAM" "C")
            (export (find-symbol "BUILD-PROGRAM" "C") "C")
            
            ;; Boot FriCAS
            (ext:chdir "/fricas0")
            (load "fricas")
            `;
            FS.writeFile('/home/web_user/.eclrc', startupScript);

        } catch(err) {
            console.error("Failed to initialize FriCAS FS:", err);
            removeRunDependency('fricas_fs_init');
        }
    }

    initFS();
});