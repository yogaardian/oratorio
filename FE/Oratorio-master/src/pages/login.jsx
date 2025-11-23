import React, { useState, useContext } from "react"; // 1. Import useContext
import { useNavigate } from "react-router-dom"; // 2. Import useNavigate
import { AuthContext } from "../context/AuthContext"; // 3. Import AuthContext
import "../pages/css/auth.css";

function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");

  // 4. Ambil fungsi 'login' dari context
  const { login } = useContext(AuthContext);
  // 5. Siapkan navigate untuk pindah halaman
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      const response = await fetch("http://localhost:5000/api/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email: email,
          password: password,
        }),
      });

      const data = await response.json();


      if (!response.ok) {
        setMessage(data.message || "Login gagal");
        return;
      }

      // Simpan user di context (dan localStorage)
      login(data.user);

      // === Redirection sesuai role ===
      if (data.user.role === "admin") {
        navigate("/admin/dashboard");
      } else {
        navigate("/dashboard");
      }

    } catch (err) {
      console.error(err);
      setMessage("Terjadi kesalahan server");
    }
  }

  return (
    <div className="auth-page-wrapper">
      <div className="auth-container">

        <h1>Masuk dan Mulai Jelajahi Semuanya!</h1>
        <p>Log into your account with your email, or create one below. Quick and easy - promise!</p>

        {/* FORM LOGIN */}
        <form className="auth-form" onSubmit={handleLogin}>
          <div className="input-group">
            <label htmlFor="email">Email</label>

            <input
              type="email"
              id="email"
              placeholder="Masukkan email Anda"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />

            <input
              type="password"
              id="password"
              placeholder="Masukkan password Anda"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <button type="submit" className="btn-primary">
            Continue
          </button>
        </form>

        {message && <p className="auth-message">{message}</p>}

        <div className="auth-links">
          <a href="/register">Register Now</a>
          <a href="#">Lupa Sandi?</a>
        </div>

        <div className="separator"><span>or continue with</span></div>

        <div className="social-logins">
          <button className="social-btn">Google</button>
          <button className="social-btn">Facebook</button>
        </div>

        <p className="legal-text">
          By creating an account, you agree to our <a href="#">Terms & Conditions</a>,{" "}
          <a href="#">Privacy Policy</a> and Agreement with Oratorio.
        </p>

        {/* FOOTER */}
        <div className="login-footer">
          {/* ...footer kamu tetap sama */}
        </div>
      </div>
    </div>
  );
}

export default LoginPage;