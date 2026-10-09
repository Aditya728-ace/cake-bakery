import { Link } from "react-router-dom";
import { useSite } from "../site.jsx";
import { Mail, Phone, Pin, social, LinkIcon } from "./Icons.jsx";

export default function Footer() {
  const { bakery, content } = useSite();
  if (!bakery) return <footer className="footer" />;
  const links = Object.entries(bakery.social_links || {});
  return (
    <footer className="footer">
      <div className="container footer-grid">
        <div>
          <div className="script">{bakery.tagline || "Baked with love"}</div>
          <h3>{bakery.name}</h3>
          <p className="muted-light">{content.footer_note || "Handcrafted cakes for life's sweetest moments."}</p>
        </div>
        <div>
          <h4>Explore</h4>
          <ul className="flist">
            <li><Link to="/">Home</Link></li>
            <li><Link to="/cakes">Our Cakes</Link></li>
            <li><a href="/#contact">Contact</a></li>
          </ul>
        </div>
        <div>
          <h4>Get in touch</h4>
          <ul className="flist">
            {bakery.phone && <li><Phone /><a href={`tel:${bakery.phone.replace(/\s/g, "")}`}>{bakery.phone}</a></li>}
            {bakery.email && <li><Mail /><a href={`mailto:${bakery.email}`}>{bakery.email}</a></li>}
            {bakery.address && <li><Pin /><span>{bakery.address}</span></li>}
          </ul>
          {links.length > 0 && (
            <div className="socials">
              {links.map(([k, url]) => {
                const Icon = social[k] || LinkIcon;
                return <a key={k} href={url} target="_blank" rel="noopener noreferrer" aria-label={k}><Icon /></a>;
              })}
            </div>
          )}
        </div>
      </div>
      <div className="container copy">© {new Date().getFullYear()} {bakery.name}. All rights reserved.</div>
    </footer>
  );
}
