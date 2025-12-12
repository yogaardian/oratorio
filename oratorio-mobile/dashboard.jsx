// ----------------------------------------------------------------------
// FILE: DashboardMobile.jsx
// Gabungan dari Header, Hero, DestinationCard, FavoriteDestinationsSection,
// ArTorioSection, VRTorioSection, dan Footer
// ----------------------------------------------------------------------

import React, { useState, useEffect } from "react";
// Impor ini perlu disesuaikan dengan struktur folder mobile Anda.
// Saya asumsikan Anda akan memindahkan aset & hooks yang dibutuhkan.
import { Link } from 'react-router-dom';
import { FaFacebookF, FaPinterestP, FaYoutube, FaInstagram } from "react-icons/fa";
// Asumsi Anda akan menyediakan file-file ini di folder yang sesuai
// import "./dashboard.css"; // Jika ada style khusus untuk wrapper mobile
// import "./header.css"; 
// import "./herosection.css";
// import "./fav-destination-section.css";
// import "./destination-section.css";
// import "./ar-torio-section.css";
// import "./footer.css";
import useScrollAnimation from '../../animations/useScrollAnimation'; // Asumsi hook ini tetap ada
import ResponsiveSearchBar from './searchbar'; // Asumsi komponen ini tetap ada

// ASSET IMPORTS (Perlu disesuaikan dengan path yang benar di project mobile Anda)
import heroImage from '../../assets/images/hero-bg2.jpg'; 
import imgKresek from '../../assets/images/fav-dest-section-monumen-kresek.jpg';
import imgMonas from '../../assets/images/fav-dest-section-tugu-monas.jpg';
import imgTugu from '../../assets/images/fav-dest-section-tugu-jogja.jpg';
import imgJamGadang from '../../assets/images/fav-dest-section-jam-gadang.jpg';
import imgBorobudur from '../../assets/images/fav-dest-section-candi-borobudur.jpg';
import imgPrambanan from '../../assets/images/fav-dest-section-candi-prambanan.jpg';


// ======================================================================
// 1. KOMPONEN: Header
// ======================================================================

function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isUserOpen, setIsUserOpen] = useState(false);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false); // Mungkin tidak perlu di mobile, tapi dipertahankan
  const [user, setUser] = useState(null);

  useEffect(() => {
    const u = localStorage.getItem("user");
    if (u) {
      setUser(JSON.parse(u));
    }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("user");
    // Anda mungkin ingin menggunakan navigasi React Router di sini (misalnya navigate('/login')) 
    // alih-alih window.location.href untuk aplikasi mobile yang sesungguhnya.
    window.location.href = "/login";
  };

  return (
    <header className="site-header">
      <div className="header-container">
        {/* LEFT: Logo */}
        <div className="header-left">
          <a href="/" className="header-brand">ORATORIO</a>
        </div>

        {/* CENTER MENU - Mungkin disembunyikan di mobile, tapi dipertahankan */}
        <div className="header-center">
          <a href="/" className="header-link">Home</a>
          <a href="/history" className="header-link">History</a>
          {/* Dropdown 'Torio' */}
          <div
            className="header-dropdown"
            onMouseEnter={() => setIsHistoryOpen(true)}
            onMouseLeave={() => setIsHistoryOpen(false)}
          >
            <button className="header-link dropdown-toggle">
              Torio
              <svg className="chevron-icon" width="14" height="14" viewBox="0 0 24 24">
                <path d="M7 10L12 15L17 10H7Z" fill="currentColor" />
              </svg>
            </button>
            {isHistoryOpen && (
              <div className="dropdown-menu">
                <a href="/ar" className="dropdown-item">🌀 AR Interface</a>
                <a href="/vr" className="dropdown-item">👓 VR Interface</a>
              </div>
            )}
          </div>
        </div>

        {/* RIGHT SIDE: USER */}
        <div className="header-right">
          {/* Dropdown User */}
          <div
            className="user-dropdown"
            onClick={() => setIsUserOpen(!isUserOpen)}
          >
            <div className="user-icon-container">
              <span>
                {user ? user.email.split("@")[0] : "User"}
              </span>
              <svg className="chevron-icon" width="14" height="14" viewBox="0 0 24 24">
                <path d="M7 10L12 15L17 10H7Z" fill="currentColor" />
              </svg>
            </div>

            {isUserOpen && (
              <div className="dropdown-menu user-menu">
                {!user && (
                  <>
                    <a href="/login" className="dropdown-item">Login</a>
                    <a href="/register" className="dropdown-item">Register</a>
                  </>
                )}
                {user && (
                  <>
                    <a href="/profile" className="dropdown-item">Profile</a>
                    <button onClick={handleLogout} className="dropdown-item" style={{ textAlign: "left", background: "none", border: "none", cursor: "pointer" }}>
                      Logout
                    </button>
                  </>
                )}
              </div>
            )}
          </div>

          {/* MOBILE HAMBURGER */}
          <div className="hamburger-menu" onClick={() => setIsMenuOpen(!isMenuOpen)}>
            <div className="bar"></div>
            <div className="bar"></div>
            <div className="bar"></div>
          </div>

        </div>
      </div>

      {/* MOBILE MENU */}
      <div className={`header-links-mobile ${isMenuOpen ? "active" : ""}`}>
        <a href="/" className="header-link">Home</a>
        <a href="/history" className="header-link">History</a>
        {!user && (
          <>
            <a href="/login" className="header-link">Login</a>
            <a href="/register" className="header-link">Register</a>
          </>
        )}
        {user && (
          <>
            <a href="/profile" className="header-link">Profile</a>
            <a onClick={handleLogout} className="header-link">Logout</a>
          </>
        )}
      </div>
    </header>
  );
}

// ======================================================================
// 2. KOMPONEN: Hero
// ======================================================================

function Hero() {
  return (
    <div className="hero-section" style={{ backgroundImage: `url(${heroImage})` }}>
      <div className="hero-overlay"></div>
      <div className="hero-content">
        <h1 className="hero-title">Jelajahi Bersama Oratorio</h1>
        <p className="hero-subtitle">Plan better with 300,000+ travel experiences:</p>
        <div className="search-bar-wrapper">
          <ResponsiveSearchBar />
        </div>
        <p className="hero-tagline">Hidupkan Kembali Sejarah. Jelajahi Budaya Indonesia di Mana Saja.</p>
      </div>
    </div>
  );
}

// ======================================================================
// 3. KOMPONEN: DestinationCard
// ======================================================================

function DestinationCard({ imageSrc, name }) {
  return (
    <div className="destination-card">
      <img src={imageSrc} alt={name} className="card-image" />
      <div className="card-overlay"></div>
      <h3 className="card-name">{name}</h3>
    </div>
  );
}

// ======================================================================
// 4. KOMPONEN: FavoriteDestinationsSection
// ======================================================================

const destinationsData = [
  { name: "Monumen Kresek", image: imgKresek },
  { name: "Monas", image: imgMonas },
  { name: "Tugu Yogyakarta", image: imgTugu },
  { name: "Jam Gadang", image: imgJamGadang },
  { name: "Candi Borobudur", image: imgBorobudur },
  { name: "Candi Prambanan", image: imgPrambanan },
];

function FavoriteDestinationsSection() {
  const sectionRef = useScrollAnimation();

  return (
    <section ref={sectionRef} className="fav-destinations-section">
      <div className="section-container">
        <h2 className="section-title animate-on-scroll">Destinasi Favorit</h2>
        <div className="destinations-grid">
          {destinationsData.map((destination, index) => (
            <div key={index} className={`animate-on-scroll stagger-${index + 1}`}>
              <DestinationCard
                name={destination.name}
                imageSrc={destination.image}
              />
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ======================================================================
// 5. KOMPONEN: ArTorioSection
// ======================================================================

const ArTorioSection = () => {
  return (
    <section className="ar-torio-section">
      <div className="section-header">
        <div className="line"></div>
        <h2 className="section-title">AR TORIO</h2>
        <div className="line"></div>
      </div>
      <h1>Jelajahi Warisan Budaya</h1>
      
      {/* Contoh Item Preview (Menggunakan Borobudur sebagai placeholder) */}
      <div className="ar-card-container">
        {/* Tampilkkan beberapa card preview AR jika ada */}
        <div className="ar-card">
          <img src={imgBorobudur} alt="Candi Borobudur" className="ar-image" />
          <div className="ar-card-content">
            <h3>Candi Borobudur</h3>
          </div>
        </div>
        <div className="arrow-button">›</div>
      </div>
      <Link to="/gallery" className="btn-explore">
        Lihat Semua Koleksi AR
      </Link>
    </section>
  );
};

// ======================================================================
// 6. KOMPONEN: VRTorioSection
// ======================================================================

function VRTorioSection() { 
  const destinations = [
    {
      slug: 'candi-borobudur', 
      image: imgBorobudur,
      title: "Candi Borobudur",
      location: "Magelang, Jawa Tengah",
    },
    {
      slug: 'monumen-nasional', 
      image: imgMonas,
      title: "Monumen Nasional",
      location: "Jakarta, DKI Jakarta",
    },
    {
      slug: 'tugu-jogja', 
      image: imgTugu,
      title: "Tugu Jogjakarya",
      location: "D.I.Yogyakarta",
    },
    {
      slug: 'jam-gadang', 
      image: imgJamGadang,
      title: "Jam Gadang",
      location: "Bukit Tinggi, Sumatera",
    },
  ];

  return (
    <section className="ar-torio-section vr-torio-section"> {/* Tambahkan class vr-torio-section jika ada style khusus */}
      <div className="section-header">
        <div className="line"></div>
        <h2 className="section-title">VR TORIO</h2>
        <div className="line"></div>
      </div>
      <div className="ar-card-container">
        {destinations.map((item) => (
          <Link to={`/vr/${item.slug}`} key={item.slug} className="ar-card-link">
            <div className="ar-card">
              <img src={item.image} alt={item.title} className="ar-image" />
              <div className="ar-card-content">
                <p className="ar-location">📍 {item.title}, {item.location}</p>
              </div>
            </div>
          </Link>
        ))}
        <div className="arrow-button">›</div>
      </div>
    </section>
  );
}

// ======================================================================
// 7. KOMPONEN: Footer
// ======================================================================

function Footer() {
  return (
    <footer className="footer">
      {/* Social Media */}
      <div className="footer-social">
        <FaFacebookF />
        <FaPinterestP />
        <FaYoutube />
        <FaInstagram />
      </div>

      {/* Footer Links */}
      <div className="footer-link">
        <div className="footer-column">
          <a href="#">Help Center</a>
          <a href="#">FAQ</a>
          <a href="#">About Oratorio</a>
        </div>
        <div className="footer-column">
          <a href="#">Destinasi</a>
          <a href="#">Augmented Reality Interface</a>
          <a href="#">Virtual Reality Interface</a>
        </div>
        <div className="footer-column">
          <a href="#">Kebijakan Privasi</a>
          <a href="#">Syarat & Ketentuan</a>
          <a href="#">Help Center</a>
        </div>
      </div>

      {/* Copyright */}
      <div className="footer-bottom">
        <p>© 2025 Oratorio, Inc.</p>
      </div>
    </footer>
  );
}


// ======================================================================
// 8. KOMPONEN UTAMA DASHBOARD MOBILE
// ======================================================================

function DashboardMobile() {
  return (
    <div className="dashboard-mobile-wrapper">
      <Header />
      <main>
        <Hero />
        <FavoriteDestinationsSection />
        <ArTorioSection />
        <VRTorioSection />
      </main>
      <Footer />
    </div>
  );
}

export default DashboardMobile;