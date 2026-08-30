import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Sun,
  Moon,
  Github,
  ChevronDown,
  Download,
  Terminal,
  ExternalLink,
  Apple,
  Laptop,
  Check,
  Copy,
  ArrowRight,
  Shield,
  Layers,
  Sparkles
} from "lucide-react";
import { SiDiscord } from "react-icons/si";

import { GithubRelease } from "./types";
import {
  fetchGithubReleases,
  FALLBACK_RELEASE_TR,
  FALLBACK_RELEASE_EN,
  detectOS,
  getRecommendedAsset,
  formatBytes
} from "./utils/github";

import DownloadModal from "./components/DownloadModal";

const fadeIn = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, ease: [0.16, 1, 0.3, 1] }
  }
};

const staggerContainer = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.12,
      delayChildren: 0.05
    }
  }
};

export default function App() {
  const [theme, setTheme] = useState<"light" | "dark">(() => {
    const saved = localStorage.getItem("hilal-theme");
    return saved === "light" ? "light" : "dark";
  });

  const [lang, setLang] = useState<"tr" | "en">(() => {
    const saved = localStorage.getItem("hilal-lang");
    return saved === "en" || saved === "tr" ? saved : "tr";
  });

  const [release, setRelease] = useState<GithubRelease | null>(null);
  const [isDownloadOpen, setIsDownloadOpen] = useState<boolean>(false);
  const [detectedOS, setDetectedOS] = useState<string>("other");
  const [activeFaq, setActiveFaq] = useState<number | null>(null);
  const [copiedClone, setCopiedClone] = useState<boolean>(false);

  useEffect(() => {
    setDetectedOS(detectOS());
  }, []);

  useEffect(() => {
    const root = window.document.documentElement;
    if (theme === "dark") {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }
    localStorage.setItem("hilal-theme", theme);
  }, [theme]);

  useEffect(() => {
    localStorage.setItem("hilal-lang", lang);
  }, [lang]);

  useEffect(() => {
    const loadData = async () => {
      try {
        const data = await fetchGithubReleases();
        if (data && data.length > 0) {
          setRelease(data[0]);
        } else {
          setRelease(lang === "en" ? FALLBACK_RELEASE_EN : FALLBACK_RELEASE_TR);
        }
      } catch {
        setRelease(lang === "en" ? FALLBACK_RELEASE_EN : FALLBACK_RELEASE_TR);
      }
    };
    loadData();
  }, [lang]);

  const toggleTheme = () => {
    setTheme((prev) => (prev === "dark" ? "light" : "dark"));
  };

  const scrollToId = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  const activeRelease = release || (lang === "en" ? FALLBACK_RELEASE_EN : FALLBACK_RELEASE_TR);
  const recommendedAsset = activeRelease?.assets
    ? getRecommendedAsset(activeRelease.assets, detectedOS as any)
    : null;

  const handleCopyCommand = () => {
    const cmd = "git clone https://github.com/VastSea0/hilal-browser.git && cd hilal-browser && ./bin/hil setup";
    navigator.clipboard.writeText(cmd);
    setCopiedClone(true);
    setTimeout(() => setCopiedClone(false), 2000);
  };

  const isDark = theme === "dark";

  const t = {
    tr: {
      nav: {
        features: "Özellikler",
        download: "İndir",
        github: "GitHub",
        getHilal: "Hilal'i Edin",
      },
      hero: {
        tagline: "Web sizin olsun.",
        subtitle:
          "Gözetimsiz, kısıtlamasız ve bağımsız bir masaüstü tarayıcısı. Yarı saydam Tahoe kenar çubuğu, izole konteyner çalışma alanları ve dahili gizlilik kalkanı ile internette tam kontrolü yeniden kazanın.",
        downloadBtn: {
          macos: "macOS için İndir",
          windows: "Windows için İndir",
          linux: "Linux için İndir",
          other: "Alpha Sürümünü İndir",
        },
        viewAllDownloads: "Tüm platformlar (.dmg, .exe, .deb, .zip)",
      },
      stories: [
        {
          tag: "01 / TAHOE ARAYÜZÜ",
          title: "Göz yormayan, dikkati sayfalara veren arayüz.",
          description:
            "Sekmeler solda, dikkatiniz tam merkezde. Web sayfasının renk tonlarına usulca uyum sağlayan yarı saydam kenar çubuğu ve kalabalığı ortadan kaldıran kompakt araç çubuğu.",
          image: isDark ? "/welcome-compact-vertical.png" : "/welcome-standard-vertical.png",
          alt: "Hilal Tahoe Sidebar Arayüzü",
        },
        {
          tag: "02 / ÇALIŞMA ALANLARI",
          title: "İş, kişisel yaşam ve projeleriniz. Tamamen izole.",
          description:
            "Sekmeler sadece görünüşte ayrılmaz; Multi-Account Containers sayesinde her çalışma alanı bağımsız çerezler ve oturumlar barındırır. Farklı hesaplar için onlarca pencere açma karmaşasına son verin.",
          image: "/welcome-workspaces-on.png",
          alt: "Hilal İzole Konteyner Çalışma Alanları",
        },
        {
          tag: "03 / MAHREMİYET VE GİZLİLİK",
          title: "Sıfır gözetim. Dahili kalkan ve sayfa temizleyici.",
          description:
            "uBlock Origin varsayılan olarak dahildir; telemetri ve arka plan izleyicileri kökten engellenir. Element Zapper ile dikkatinizi dağıtan her türlü banner veya öğeyi tek tıkla sonsuza dek yok edin.",
          image: "/welcome-toolbar-hidden.png",
          alt: "Hilal Minimalist Kompakt Mod",
        },
      ],
      openSourceSection: {
        tag: "04 / AÇIK KAYNAK VE MİMARİ",
        title: "Bağımsız bir katman. Güvenilir Firefox Gecko motoru.",
        description:
          "Hilal, upstream Firefox Gecko motoru üzerine inşa edilen şeffaf ve açık kaynaklı bir yama katmanıdır. Tüm Firefox eklentileriniz (AMO) ve güvenlik güncellemeleri gecikmeksizin eksiksiz çalışır.",
        commandLabel: "Geliştiriciler için tek satırda derleme:",
      },
      downloadSection: {
        title: "Hilal'i Deneyin.",
        subtitle: "Özgür, hızlı ve sizin kontrolünüzde bir internet.",
        platforms: [
          {
            name: "macOS",
            spec: "Apple Silicon & Intel • Universal .dmg",
            icon: <Apple className="w-6 h-6" />,
          },
          {
            name: "Windows",
            spec: "Windows 10/11 • 64-bit .exe & Taşınabilir .zip",
            icon: <Laptop className="w-6 h-6" />,
          },
          {
            name: "Linux",
            spec: "Ubuntu / Debian .deb • AppImage • Tarball",
            icon: <Terminal className="w-6 h-6" />,
          },
        ],
        directDownload: "İndir",
      },
      faq: {
        title: "Sıkça Sorulan Sorular",
        items: [
          {
            q: "Hilal Browser nedir ve geleneksel çatallamalardan (fork) farkı nedir?",
            a: "Hilal, Firefox kod tabanından kopan hantal bir fork değildir. Upstream Firefox Gecko motoru üzerine Rust ile yazılmış `hil` aracıyla deklaratif patch ve overlay dosyaları uygular. Bu sayede Firefox'un en son güvenlik yamalarını ve performans güncellemelerini gecikmeksizin alır.",
          },
          {
            q: "Mevcut Firefox eklentilerimi ve şifrelerimi kullanabilir miyim?",
            a: "Evet. Hilal standart Firefox Add-ons mağazası (AMO) ve Gecko eklenti ekosistemiyle %100 uyumludur. uBlock Origin varsayılan olarak dahildir; Bitwarden, Dark Reader ve sevdiğiniz tüm eklentileri tek tıkla yükleyebilirsiniz.",
          },
          {
            q: "Çalışma Alanları (Workspaces) oturumları nasıl ayırır?",
            a: "Her çalışma alanı Firefox Multi-Account Containers altyapısını kullanarak çerezleri ve oturumları izole eder. İş, okul ve kişisel hesaplarınıza aynı tarayıcı penceresinde birbirine karışmadan giriş yapabilirsiniz.",
          },
          {
            q: "Verilerim güvende mi? Telemetri toplanıyor mu?",
            a: "Sıfır telemetri politikası uygulanır. Mozilla'nın tüm analitik, telemetri ve hata raporlama sunucuları patch seviyesinde engellenmiştir. Hiçbir veriniz asla kaydedilmez ve dışarıya aktarılmaz.",
          },
        ],
      },
      footer: {
        copyright: "Hilal Browser Projesi. Mozilla Kamu Lisansı (MPL 2.0) ile korunmaktadır.",
        source: "Kaynak Kodu",
        releases: "Sürümler",
        discord: "Discord",
      },
    },
    en: {
      nav: {
        features: "Features",
        download: "Download",
        github: "GitHub",
        getHilal: "Get Hilal",
      },
      hero: {
        tagline: "The web, on your terms.",
        subtitle:
          "An uncompromised, surveillance-free desktop browser built on Firefox Gecko. Featuring translucent Tahoe sidebars, isolated multi-account workspaces, and built-in tracking protection.",
        downloadBtn: {
          macos: "Download for macOS",
          windows: "Download for Windows",
          linux: "Download for Linux",
          other: "Download Alpha Build",
        },
        viewAllDownloads: "All platforms (.dmg, .exe, .deb, .zip)",
      },
      stories: [
        {
          tag: "01 / TAHOE INTERFACE",
          title: "A translucent Tahoe sidebar that gets out of your way.",
          description:
            "Tabs on the left, your focus on the center. A clean window that softly adapts to the website's color palette, paired with an auto-hiding compact toolbar.",
          image: isDark ? "/welcome-compact-vertical.png" : "/welcome-standard-vertical.png",
          alt: "Hilal Tahoe Sidebar Interface",
        },
        {
          tag: "02 / WORKSPACES",
          title: "Work, dev, and personal life. Strictly partitioned.",
          description:
            "Tabs aren't just visually grouped; each workspace runs in a true container context with isolated cookies and logins. No need to juggle dozens of separate windows.",
          image: "/welcome-workspaces-on.png",
          alt: "Hilal Multi-Account Workspaces",
        },
        {
          tag: "03 / PRIVACY & CONTROL",
          title: "Zero surveillance. Built-in shield & Element Zapper.",
          description:
            "Pre-packaged with uBlock Origin to neutralize intrusive ads and trackers. Zero telemetry. Vaporize annoying banners with a single click using the Element Zapper.",
          image: "/welcome-toolbar-hidden.png",
          alt: "Hilal Compact Focused Mode",
        },
      ],
      openSourceSection: {
        tag: "04 / ARCHITECTURE",
        title: "An open source layer. The Gecko engine you trust.",
        description:
          "Hilal runs on top of upstream Firefox Gecko as an auditable, text-only patch layer. Retaining instant security tracking and 100% Firefox add-on compatibility.",
        commandLabel: "Developer one-line setup:",
      },
      downloadSection: {
        title: "Meet Hilal.",
        subtitle: "Uncompromised, fast, and tranquil browsing.",
        platforms: [
          {
            name: "macOS",
            spec: "Apple Silicon & Intel • Universal .dmg",
            icon: <Apple className="w-6 h-6" />,
          },
          {
            name: "Windows",
            spec: "Windows 10/11 • 64-bit .exe & Portable .zip",
            icon: <Laptop className="w-6 h-6" />,
          },
          {
            name: "Linux",
            spec: "Ubuntu / Debian .deb • AppImage • Tarball",
            icon: <Terminal className="w-6 h-6" />,
          },
        ],
        directDownload: "Download",
      },
      faq: {
        title: "Frequently Asked Questions",
        items: [
          {
            q: "What is Hilal Browser and how does it differ from a hard fork?",
            a: "Hilal is not a detached codebase copy. It applies declarative patch files onto upstream Firefox via the native `hil` Rust patch manager. This guarantees instant security tracking and zero fork rot.",
          },
          {
            q: "Can I use standard Firefox extensions?",
            a: "Yes. Hilal maintains full compatibility with the Firefox Add-ons ecosystem (AMO) and Gecko engine. uBlock Origin is pre-installed out of the box.",
          },
          {
            q: "How do Workspaces isolate sessions?",
            a: "Each workspace uses Firefox Multi-Account Containers to strictly partition cookies, logins, and storage between different contexts.",
          },
          {
            q: "Is there any telemetry or tracking?",
            a: "Zero telemetry. Mozilla telemetry endpoints and background analytics pingers are killed at the engine and preference level.",
          },
        ],
      },
      footer: {
        copyright: "Hilal Browser Project. Licensed under the Mozilla Public License 2.0.",
        source: "Source Code",
        releases: "Releases",
        discord: "Discord",
      },
    },
  };

  const activeT = t[lang] || t.tr;

  const getDynamicBtnLabel = () => {
    if (detectedOS === "macos") return activeT.hero.downloadBtn.macos;
    if (detectedOS === "windows") return activeT.hero.downloadBtn.windows;
    if (detectedOS === "linux") return activeT.hero.downloadBtn.linux;
    return activeT.hero.downloadBtn.other;
  };

  return (
    <div
      className={`min-h-screen font-sans transition-colors duration-300 ${
        isDark ? "bg-[#08080a] text-[#f4f4f6]" : "bg-[#faf9f7] text-[#18181b]"
      }`}
    >
      {/* 1. Calm Minimal Navbar */}
      <nav
        className={`fixed top-0 left-0 right-0 z-50 border-b transition-colors ${
          isDark ? "nav-blur-dark border-white/[0.06]" : "nav-blur-light border-black/[0.06]"
        }`}
      >
        <div className="mx-auto max-w-5xl px-6 h-16 flex items-center justify-between">
          {/* Logo & Name */}
          <motion.div
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
            className="flex items-center gap-2.5 cursor-pointer"
          >
            <img
              src="/default128.png"
              alt="Hilal Logo"
              className="w-6 h-6 object-contain"
            />
            <span className={`text-sm font-bold tracking-tight ${isDark ? "text-white" : "text-black"}`}>
              Hilal
            </span>
          </motion.div>

          {/* Center Links */}
          <div
            className={`hidden sm:flex items-center gap-8 text-xs font-medium ${
              isDark ? "text-neutral-400" : "text-neutral-600"
            }`}
          >
            <button
              onClick={() => scrollToId("features")}
              className={`hover:text-blue-500 transition-colors ${isDark ? "hover:text-white" : "hover:text-black"}`}
            >
              {activeT.nav.features}
            </button>
            <button
              onClick={() => scrollToId("download")}
              className={`hover:text-blue-500 transition-colors ${isDark ? "hover:text-white" : "hover:text-black"}`}
            >
              {activeT.nav.download}
            </button>
            <a
              href="https://github.com/VastSea0/hilal-browser"
              target="_blank"
              rel="noopener noreferrer"
              className={`hover:text-blue-500 transition-colors ${isDark ? "hover:text-white" : "hover:text-black"}`}
            >
              {activeT.nav.github}
            </a>
          </div>

          {/* Right Utilities */}
          <div className="flex items-center gap-3">
            {/* Lang Switch */}
            <button
              onClick={() => setLang(lang === "tr" ? "en" : "tr")}
              className={`text-xs font-mono font-semibold px-2 py-1 rounded-md transition-colors ${
                isDark
                  ? "text-neutral-400 hover:text-white hover:bg-white/10"
                  : "text-neutral-600 hover:text-black hover:bg-black/5"
              }`}
              title={lang === "tr" ? "Switch to English" : "Türkçe'ye Geç"}
            >
              {lang === "tr" ? "EN" : "TR"}
            </button>

            {/* Theme Switch */}
            <button
              onClick={toggleTheme}
              className={`p-1.5 rounded-md transition-colors ${
                isDark
                  ? "text-neutral-400 hover:text-white hover:bg-white/10"
                  : "text-neutral-600 hover:text-black hover:bg-black/5"
              }`}
              aria-label="Theme Toggle"
            >
              {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>

            {/* CTA Button */}
            <motion.button
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.97 }}
              onClick={() => setIsDownloadOpen(true)}
              className={`text-xs font-semibold px-4 py-2 rounded-full transition-all shadow-sm ${
                isDark
                  ? "bg-white text-black hover:bg-neutral-100"
                  : "bg-[#18181b] text-white hover:bg-black"
              }`}
            >
              {activeT.nav.getHilal}
            </motion.button>
          </div>
        </div>
      </nav>

      {/* 2. Serene Hero Section */}
      <section className="pt-36 sm:pt-48 pb-20 px-6 max-w-5xl mx-auto text-center">
        <motion.div
          variants={staggerContainer}
          initial="hidden"
          animate="visible"
          className="space-y-6"
        >
          {/* Main Tagline */}
          <motion.h1
            variants={fadeIn}
            className={`text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-tight leading-[1.08] ${
              isDark ? "text-white" : "text-[#111113]"
            }`}
          >
            {activeT.hero.tagline}
          </motion.h1>

          {/* Subtitle */}
          <motion.p
            variants={fadeIn}
            className={`max-w-2xl mx-auto text-sm sm:text-base md:text-lg leading-relaxed font-normal ${
              isDark ? "text-neutral-400" : "text-neutral-600"
            }`}
          >
            {activeT.hero.subtitle}
          </motion.p>

          {/* Hero Download CTA */}
          <motion.div
            variants={fadeIn}
            className="pt-4 flex flex-col items-center gap-3"
          >
            <motion.button
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.97 }}
              onClick={() => setIsDownloadOpen(true)}
              className="inline-flex items-center gap-2.5 bg-blue-600 hover:bg-blue-500 text-white font-semibold text-sm sm:text-base px-8 py-3.5 rounded-full shadow-lg shadow-blue-600/25 transition-all"
            >
              {detectedOS === "macos" && <Apple className="w-5 h-5" />}
              {detectedOS === "windows" && <Laptop className="w-5 h-5" />}
              {detectedOS !== "macos" && detectedOS !== "windows" && <Download className="w-5 h-5" />}
              <span>{getDynamicBtnLabel()}</span>
            </motion.button>

            <button
              onClick={() => setIsDownloadOpen(true)}
              className={`text-xs transition-colors mt-1 font-medium ${
                isDark ? "text-neutral-500 hover:text-neutral-300" : "text-neutral-500 hover:text-neutral-800"
              }`}
            >
              {activeT.hero.viewAllDownloads}
            </button>
          </motion.div>
        </motion.div>

        {/* Main Hero Product Image Showcase */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
          className={`mt-16 sm:mt-20 rounded-2xl overflow-hidden hover-lift ${
            isDark ? "browser-frame-dark bg-[#0e0e12]" : "browser-frame-light bg-[#ffffff]"
          }`}
        >
          <img
            src={isDark ? "/welcome-home-preview-black.png" : "/welcome-home-preview.png"}
            alt="Hilal Browser Tahoe Interface"
            className="w-full h-auto block select-none pointer-events-none"
          />
        </motion.div>
      </section>

      {/* 3. Calm Editorial Stories (One by one, generous breathing room) */}
      <section className="py-24 space-y-36 max-w-5xl mx-auto px-6" id="features">
        {activeT.stories.map((story, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, y: 28 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="grid grid-cols-1 lg:grid-cols-12 gap-10 sm:gap-16 items-center"
          >
            {/* Text side */}
            <div
              className={`lg:col-span-5 space-y-4 ${
                index % 2 === 1 ? "lg:order-2" : "lg:order-1"
              }`}
            >
              <span className="text-[11px] font-mono tracking-widest text-blue-500 uppercase font-semibold block">
                {story.tag}
              </span>
              <h2
                className={`text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight leading-snug ${
                  isDark ? "text-white" : "text-[#111113]"
                }`}
              >
                {story.title}
              </h2>
              <p
                className={`text-sm sm:text-base leading-relaxed ${
                  isDark ? "text-neutral-400" : "text-neutral-600"
                }`}
              >
                {story.description}
              </p>
            </div>

            {/* Image side */}
            <motion.div
              whileHover={{ y: -4 }}
              transition={{ duration: 0.3 }}
              className={`lg:col-span-7 rounded-2xl overflow-hidden hover-lift ${
                isDark
                  ? "browser-frame-dark bg-[#0e0e12]"
                  : "browser-frame-light bg-[#ffffff]"
              } ${index % 2 === 1 ? "lg:order-1" : "lg:order-2"}`}
            >
              <img
                src={story.image}
                alt={story.alt}
                className="w-full h-auto block select-none"
              />
            </motion.div>
          </motion.div>
        ))}

        {/* Open Source / Architecture Moment */}
        <motion.div
          initial={{ opacity: 0, y: 28 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          className={`pt-16 border-t text-center max-w-3xl mx-auto space-y-6 ${
            isDark ? "border-white/[0.06]" : "border-black/[0.06]"
          }`}
        >
          <span className="text-[11px] font-mono tracking-widest text-blue-500 uppercase font-semibold block">
            {activeT.openSourceSection.tag}
          </span>
          <h2
            className={`text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight ${
              isDark ? "text-white" : "text-[#111113]"
            }`}
          >
            {activeT.openSourceSection.title}
          </h2>
          <p
            className={`text-sm sm:text-base leading-relaxed ${
              isDark ? "text-neutral-400" : "text-neutral-600"
            }`}
          >
            {activeT.openSourceSection.description}
          </p>

          {/* Quick Terminal Snippet */}
          <div
            className={`mt-8 inline-flex items-center gap-3 px-4 py-2.5 rounded-xl border text-xs font-mono transition-colors ${
              isDark
                ? "border-white/[0.08] bg-[#111114] text-neutral-300"
                : "border-black/[0.08] bg-[#ffffff] text-neutral-800 shadow-sm"
            }`}
          >
            <span className="text-blue-500 font-bold">$</span>
            <span className="select-all">git clone https://github.com/VastSea0/hilal-browser.git && cd hilal-browser && ./bin/hil setup</span>
            <button
              onClick={handleCopyCommand}
              className={`p-1 rounded transition-colors ${
                isDark ? "text-neutral-400 hover:text-white" : "text-neutral-500 hover:text-black"
              }`}
              title="Copy"
            >
              {copiedClone ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
            </button>
          </div>
        </motion.div>
      </section>

      {/* 4. Minimal Download Section */}
      <section
        className={`py-24 border-t transition-colors ${
          isDark ? "border-white/[0.06] bg-[#0c0c0f]" : "border-black/[0.06] bg-[#f4f3f0]"
        }`}
        id="download"
      >
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h2
            className={`text-3xl sm:text-4xl font-bold tracking-tight ${
              isDark ? "text-white" : "text-[#111113]"
            }`}
          >
            {activeT.downloadSection.title}
          </h2>
          <p
            className={`mt-2 text-sm ${
              isDark ? "text-neutral-400" : "text-neutral-600"
            }`}
          >
            {activeT.downloadSection.subtitle}
          </p>

          {/* 3 Calm Platform Cards */}
          <div className="mt-12 grid grid-cols-1 sm:grid-cols-3 gap-5">
            {activeT.downloadSection.platforms.map((p, idx) => (
              <motion.div
                key={idx}
                whileHover={{ y: -4 }}
                onClick={() => setIsDownloadOpen(true)}
                className={`p-6 rounded-2xl border transition-all text-left flex flex-col justify-between cursor-pointer group shadow-sm ${
                  isDark
                    ? "border-white/[0.08] bg-[#111114] hover:border-white/[0.18] hover:bg-[#15151a]"
                    : "border-black/[0.08] bg-[#ffffff] hover:border-black/[0.18] hover:bg-[#ffffff]"
                }`}
              >
                <div>
                  <div
                    className={`transition-colors mb-4 ${
                      isDark ? "text-neutral-400 group-hover:text-blue-400" : "text-neutral-600 group-hover:text-blue-600"
                    }`}
                  >
                    {p.icon}
                  </div>
                  <h3
                    className={`text-base font-bold ${
                      isDark ? "text-white" : "text-[#111113]"
                    }`}
                  >
                    {p.name}
                  </h3>
                  <p
                    className={`mt-1 text-xs ${
                      isDark ? "text-neutral-400" : "text-neutral-500"
                    }`}
                  >
                    {p.spec}
                  </p>
                </div>

                <div className="mt-6 flex items-center gap-1.5 text-xs text-blue-500 font-semibold group-hover:translate-x-1 transition-transform">
                  <span>{activeT.downloadSection.directDownload}</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* 5. Minimal S.S.S. (FAQ) */}
      <section
        className={`py-24 border-t max-w-3xl mx-auto px-6 ${
          isDark ? "border-white/[0.06]" : "border-black/[0.06]"
        }`}
      >
        <h2
          className={`text-2xl sm:text-3xl font-bold tracking-tight text-center mb-12 ${
            isDark ? "text-white" : "text-[#111113]"
          }`}
        >
          {activeT.faq.title}
        </h2>

        <div className="space-y-4">
          {activeT.faq.items.map((item, idx) => {
            const isOpen = activeFaq === idx;
            return (
              <div
                key={idx}
                className={`border-b pb-4 transition-colors ${
                  isDark ? "border-white/[0.06]" : "border-black/[0.06]"
                }`}
              >
                <button
                  onClick={() => setActiveFaq(isOpen ? null : idx)}
                  className={`w-full flex items-center justify-between text-left py-2 text-sm sm:text-base font-semibold transition-colors ${
                    isDark ? "text-white hover:text-blue-400" : "text-[#18181b] hover:text-blue-600"
                  }`}
                >
                  <span>{item.q}</span>
                  <ChevronDown
                    className={`w-4 h-4 transition-transform duration-200 shrink-0 ml-4 ${
                      isOpen ? "rotate-180" : ""
                    } ${isDark ? "text-neutral-400" : "text-neutral-500"}`}
                  />
                </button>
                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.2 }}
                      className="overflow-hidden"
                    >
                      <p
                        className={`pt-2 text-xs sm:text-sm leading-relaxed ${
                          isDark ? "text-neutral-400" : "text-neutral-600"
                        }`}
                      >
                        {item.a}
                      </p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>
      </section>

      {/* 6. Tranquil Single-line Footer */}
      <footer
        className={`py-12 border-t text-xs transition-colors ${
          isDark ? "border-white/[0.06] text-neutral-500" : "border-black/[0.06] text-neutral-500"
        }`}
      >
        <div className="max-w-5xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p>© {new Date().getFullYear()} {activeT.footer.copyright}</p>
          <div className="flex items-center gap-6 font-medium">
            <a
              href="https://github.com/VastSea0/hilal-browser"
              target="_blank"
              rel="noopener noreferrer"
              className={`transition-colors ${isDark ? "hover:text-white" : "hover:text-black"}`}
            >
              {activeT.footer.source}
            </a>
            <a
              href="https://github.com/VastSea0/hilal-browser/releases"
              target="_blank"
              rel="noopener noreferrer"
              className={`transition-colors ${isDark ? "hover:text-white" : "hover:text-black"}`}
            >
              {activeT.footer.releases}
            </a>
            <a
              href="https://discord.gg/JZJ4tmPHFw"
              target="_blank"
              rel="noopener noreferrer"
              className={`transition-colors ${isDark ? "hover:text-white" : "hover:text-black"}`}
            >
              {activeT.footer.discord}
            </a>
          </div>
        </div>
      </footer>

      {/* Calm Download Modal */}
      <DownloadModal
        isOpen={isDownloadOpen}
        onClose={() => setIsDownloadOpen(false)}
        release={activeRelease}
        lang={lang}
        theme={theme}
      />
    </div>
  );
}
