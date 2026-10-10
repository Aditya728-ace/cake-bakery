import { useEffect } from "react";
import { Route, Routes, useLocation } from "react-router-dom";
import Header from "./components/Header.jsx";
import Footer from "./components/Footer.jsx";
import Home from "./pages/Home.jsx";
import Gallery from "./pages/Gallery.jsx";
import CakeDetail from "./pages/CakeDetail.jsx";
import NotFound from "./pages/NotFound.jsx";
import ErrorBoundary from "./components/ErrorBoundary.jsx";
import { useSite } from "./site.jsx";

function ScrollTop() {
  const { pathname } = useLocation();
  useEffect(() => window.scrollTo({ top: 0 }), [pathname]);
  return null;
}

export default function App() {
  const { error, loading } = useSite();
  const { pathname } = useLocation();
  return (
    <ErrorBoundary key={pathname}>
      <ScrollTop />
      <Header />
      <main>
        {error && !loading ? (
          <div className="container notice">
            <h2>We'll be right back</h2>
            <p>{error}</p>
            <button className="btn" onClick={() => location.reload()}>Try again</button>
          </div>
        ) : (
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/cakes" element={<Gallery />} />
            <Route path="/cakes/:slug" element={<CakeDetail />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        )}
      </main>
      <Footer />
    </ErrorBoundary>
  );
}
