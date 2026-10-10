import { useEffect, useState } from "react";
import { Link, NavLink, useLocation } from "react-router-dom";
import { useSite } from "../site.jsx";
import { whatsappLink } from "../api.js";

export default function Header() {
  const { bakery, content } = useSite();
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const { pathname } = useLocation();
  useEffect(() => {
    setOpen(false);
  }, [pathname]);
  useEffect(() => {
    const on = () => setScrolled(window.scrollY > 12);
    on();
    window.addEventListener("scroll", on, { passive: true });
    return () => window.removeEventListener("scroll", on);
  }, []);
  const wa = bakery && whatsappLink(bakery.whatsapp_number, bakery.name);
  return (
    <>
      {content.announcement && <div className="announce">{content.announcement}</div>}
      <header className={`header ${scrolled ? "scrolled" : ""}`}>
        <div className="container header-in">
          <Link to="/" className="brand" aria-label="Home">
            {bakery?.logo_url && <img src={bakery.logo_url} alt="" className="brand-logo" />}
            <span className="brand-name">{bakery?.name || "\u00a0"}</span>
          </Link>
          <button className="burger" aria-label="Menu" aria-expanded={open} onClick={() => setOpen(!open)}>
            <span /><span /><span />
          </button>
          <nav className={`nav ${open ? "open" : ""}`}>
            <NavLink to="/" end>Home</NavLink>
            <NavLink to="/cakes">Our Cakes</NavLink>
            <a href="/#contact" onClick={() => setOpen(false)}>Contact</a>
            {wa && <a className="btn btn-sm" href={wa} target="_blank" rel="noopener noreferrer">Order on WhatsApp</a>}
          </nav>
        </div>
      </header>
    </>
  );
}
