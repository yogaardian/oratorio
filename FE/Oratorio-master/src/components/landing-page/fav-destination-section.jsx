import React from 'react';
import DestinationCard from './destination-section';
import './fav-destination-section.css';
import useScrollAnimation from '../../animations/useScrollAnimation';

// Impor setiap gambar dari folder assets
import imgKresek from '../../assets/images/fav-dest-section-monumen-kresek.jpg';
import imgMonas from '../../assets/images/fav-dest-section-tugu-monas.jpg';
import imgTugu from '../../assets/images/fav-dest-section-tugu-jogja.jpg';
import imgJamGadang from '../../assets/images/fav-dest-section-jam-gadang.jpg';
import imgBorobudur from '../../assets/images/fav-dest-section-candi-borobudur.jpg';
import imgPrambanan from '../../assets/images/fav-dest-section-candi-prambanan.jpg';

const destinationsData = [
  { name: "Monumen Kresek", image: imgKresek },
  { name: "Monas", image: imgMonas },
  { name: "Tugu Yogyakarta", image: imgTugu },
  { name: "Jam Gadang", image: imgJamGadang },
  { name: "Candi Borobudur", image: imgBorobudur },
  { name: "Candi Prambanan", image: imgPrambanan },
];

function FavoriteDestinationsSection() {
  // 2. Panggil hook untuk mendapatkan 'ref' yang akan kita pasang ke section
  const sectionRef = useScrollAnimation();

  return (
    // 3. Pasang 'ref' ke elemen <section> utama
    <section ref={sectionRef} className="fav-destinations-section">
      <div className="section-container">
        {/* Tambahkan class 'animate-on-scroll' pada judul */}
        <h2 className="section-title animate-on-scroll">Destinasi Favorit</h2>
        <div className="destinations-grid">
          {destinationsData.map((destination, index) => (
            // 4. Bungkus kartu dengan div dan tambahkan class animasi
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

export default FavoriteDestinationsSection;