import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Download,
  X,
  Apple,
  Laptop,
  Terminal,
  ExternalLink,
  CheckCircle2
} from "lucide-react";
import { GithubRelease, GithubAsset } from "../types";
import { formatBytes } from "../utils/github";

interface DownloadModalProps {
  isOpen: boolean;
  onClose: () => void;
  release: GithubRelease | null;
  lang: "tr" | "en";
  theme: "light" | "dark";
}

export default function DownloadModal({
  isOpen,
  onClose,
  release,
  lang,
  theme,
}: DownloadModalProps) {
  const [downloadedAsset, setDownloadedAsset] = useState<GithubAsset | null>(null);

  const t = {
    tr: {
      title: "Hilal Browser'ı İndir",
      subtitle: "İşletim sisteminiz için derlenmiş resmi kurulum paketini seçin.",
      downloadStarted: "İndirme Başlatıldı",
      downloadDesc: "Kurulum paketi doğrudan GitHub üzerinden indiriliyor.",
      close: "Kapat",
      redownload: "Tekrar İndir",
      viewReleases: "Tüm sürümleri GitHub üzerinde inceleyin",
      platforms: {
        macos: "macOS (Apple Silicon & Intel)",
        windowsExe: "Windows (Kurulum Paketi .exe)",
        windowsZip: "Windows (Taşınabilir .zip)",
        linuxDeb: "Linux (Debian / Ubuntu .deb)",
        linuxAppImage: "Linux (Evrensel .AppImage)",
        linuxTar: "Linux (Kaynak Arşivi .tar.gz)"
      }
    },
    en: {
      title: "Download Hilal Browser",
      subtitle: "Select the official build artifact for your operating system.",
      downloadStarted: "Download Initiated",
      downloadDesc: "The release package is downloading directly from GitHub.",
      close: "Close",
      redownload: "Download Again",
      viewReleases: "Inspect all releases on GitHub",
      platforms: {
        macos: "macOS (Apple Silicon & Intel)",
        windowsExe: "Windows (Installer .exe)",
        windowsZip: "Windows (Portable .zip)",
        linuxDeb: "Linux (Debian / Ubuntu .deb)",
        linuxAppImage: "Linux (Universal .AppImage)",
        linuxTar: "Linux (Tarball .tar.gz)"
      }
    }
  };

  const activeT = t[lang] || t.tr;
  const assets = release?.assets || [];

  useEffect(() => {
    if (isOpen) {
      setDownloadedAsset(null);
    }
  }, [isOpen]);

  const handleDownload = (asset: GithubAsset) => {
    setDownloadedAsset(asset);
    window.location.href = asset.browser_download_url;
  };

  function getPlatformInfo(name: string) {
    const n = name.toLowerCase();
    if (n.endsWith(".dmg")) return { label: activeT.platforms.macos, icon: <Apple className="w-5 h-5" /> };
    if (n.endsWith(".installer.exe") || (n.endsWith(".exe") && !n.includes("zip")))
      return { label: activeT.platforms.windowsExe, icon: <Laptop className="w-5 h-5" /> };
    if (n.endsWith(".zip")) return { label: activeT.platforms.windowsZip, icon: <Laptop className="w-5 h-5" /> };
    if (n.endsWith(".deb")) return { label: activeT.platforms.linuxDeb, icon: <Terminal className="w-5 h-5" /> };
    if (n.endsWith(".appimage")) return { label: activeT.platforms.linuxAppImage, icon: <Terminal className="w-5 h-5" /> };
    return { label: activeT.platforms.linuxTar, icon: <Terminal className="w-5 h-5" /> };
  }

  const isDark = theme === "dark";

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm"
          />

          {/* Modal Card */}
          <motion.div
            initial={{ opacity: 0, scale: 0.96, y: 12 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.96, y: 12 }}
            transition={{ duration: 0.2, ease: "easeOut" }}
            className={`relative w-full max-w-lg rounded-2xl border p-6 sm:p-8 shadow-2xl transition-colors ${
              isDark
                ? "bg-[#111114] border-white/[0.1] text-[#f4f4f6]"
                : "bg-[#ffffff] border-black/[0.1] text-[#18181b]"
            }`}
          >
            {/* Close Button */}
            <button
              onClick={onClose}
              className={`absolute top-5 right-5 p-1.5 rounded-full transition-colors ${
                isDark
                  ? "text-neutral-400 hover:text-white hover:bg-white/10"
                  : "text-neutral-500 hover:text-black hover:bg-black/5"
              }`}
            >
              <X className="w-4 h-4" />
            </button>

            {downloadedAsset ? (
              <div className="text-center py-6">
                <div className="mx-auto w-12 h-12 rounded-full bg-blue-500/15 text-blue-500 flex items-center justify-center mb-4">
                  <CheckCircle2 className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-bold tracking-tight">
                  {activeT.downloadStarted}
                </h3>
                <p className={`mt-1.5 text-sm ${isDark ? "text-neutral-400" : "text-neutral-600"}`}>
                  {activeT.downloadDesc}
                </p>
                <p className={`mt-3 text-xs font-mono px-3 py-1.5 rounded-lg inline-block ${
                  isDark ? "bg-white/5 text-neutral-300" : "bg-black/5 text-neutral-700"
                }`}>
                  {downloadedAsset.name} • {formatBytes(downloadedAsset.size)}
                </p>
                <div className="mt-6 flex justify-center gap-3">
                  <button
                    onClick={() => handleDownload(downloadedAsset)}
                    className="px-5 py-2.5 rounded-full bg-blue-600 hover:bg-blue-500 text-white text-xs font-semibold shadow-md transition-colors"
                  >
                    {activeT.redownload}
                  </button>
                  <button
                    onClick={onClose}
                    className={`px-5 py-2.5 rounded-full text-xs font-medium transition-colors ${
                      isDark ? "bg-white/10 text-neutral-200 hover:bg-white/15" : "bg-black/5 text-neutral-800 hover:bg-black/10"
                    }`}
                  >
                    {activeT.close}
                  </button>
                </div>
              </div>
            ) : (
              <div>
                <div className="mb-6">
                  <h3 className="text-xl font-bold tracking-tight">
                    {activeT.title}
                  </h3>
                  <p className={`mt-1 text-xs ${isDark ? "text-neutral-400" : "text-neutral-600"}`}>
                    {activeT.subtitle}
                  </p>
                </div>

                <div className="space-y-2 max-h-[60vh] overflow-y-auto">
                  {assets.map((asset) => {
                    const info = getPlatformInfo(asset.name);
                    return (
                      <button
                        key={asset.id}
                        onClick={() => handleDownload(asset)}
                        className={`w-full flex items-center justify-between p-3.5 rounded-xl border transition-all text-left group cursor-pointer ${
                          isDark
                            ? "border-white/[0.06] bg-white/[0.02] hover:bg-white/[0.06] hover:border-white/[0.14]"
                            : "border-black/[0.06] bg-black/[0.02] hover:bg-black/[0.05] hover:border-black/[0.12]"
                        }`}
                      >
                        <div className="flex items-center gap-3.5">
                          <div className={`transition-colors ${
                            isDark ? "text-neutral-400 group-hover:text-blue-400" : "text-neutral-600 group-hover:text-blue-600"
                          }`}>
                            {info.icon}
                          </div>
                          <div>
                            <div className="text-xs sm:text-sm font-semibold">
                              {info.label}
                            </div>
                            <div className={`text-[11px] font-mono ${
                              isDark ? "text-neutral-500" : "text-neutral-500"
                            }`}>
                              {asset.name}
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-2.5 shrink-0">
                          <span className={`text-xs font-mono ${isDark ? "text-neutral-400" : "text-neutral-500"}`}>
                            {formatBytes(asset.size)}
                          </span>
                          <div className={`p-1.5 rounded-lg transition-colors ${
                            isDark ? "bg-white/5 text-neutral-400 group-hover:bg-blue-600 group-hover:text-white" : "bg-black/5 text-neutral-600 group-hover:bg-blue-600 group-hover:text-white"
                          }`}>
                            <Download className="w-3.5 h-3.5" />
                          </div>
                        </div>
                      </button>
                    );
                  })}
                </div>

                <div className={`mt-6 pt-4 border-t text-center ${
                  isDark ? "border-white/[0.06]" : "border-black/[0.06]"
                }`}>
                  <a
                    href={release?.html_url || "https://github.com/VastSea0/hilal-browser/releases"}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 text-xs text-blue-500 hover:text-blue-600 font-medium transition-colors"
                  >
                    <span>{activeT.viewReleases}</span>
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
              </div>
            )}
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
