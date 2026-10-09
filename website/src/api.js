const BASE = (import.meta.env.VITE_API_URL || "").replace(/\/$/, "");
const DEMO = import.meta.env.VITE_DEMO === "true";

async function get(path) {
  const res = await fetch(`${BASE}${path}`, { headers: { Accept: "application/json" } });
  if (res.status === 404) {
    const e = new Error("Not found");
    e.status = 404;
    throw e;
  }
  if (!res.ok) throw new Error("Could not reach the bakery right now.");
  return res.json();
}

const demoCakes = [
  ["Royal Belgian Truffle", "Three layers of dark chocolate sponge folded with silky Belgian ganache and finished with gold-dusted curls.", ["Belgian dark chocolate", "Fresh cream", "Cocoa", "Free-range eggs", "Madagascar vanilla"], "1899"],
  ["Rose & Pistachio Dream", "A fragrant rose-water sponge layered with pistachio cream and crowned with sugared petals.", ["Rose water", "Pistachio", "Butter", "Mascarpone", "Dried rose petals"], "1599"],
  ["Burnt Orange Velvet", "Our signature red velvet brightened with caramelised orange zest and cream cheese frosting.", ["Cream cheese", "Orange zest", "Buttermilk", "Cocoa", "Vanilla"], "1399"],
  ["Ivory Vanilla Bean", "Classic vanilla bean cake with whipped ivory buttercream. Simple, soft and timeless.", ["Vanilla beans", "Butter", "Eggs", "Sugar", "Cream"], null],
  ["Salted Caramel Crown", "Golden caramel, a whisper of sea salt and tender butter sponge.", ["Caramel", "Sea salt", "Butter", "Flour", "Cream"], "1699"],
  ["Strawberry Cloud", "Light chiffon, fresh strawberries and whipped vanilla cream.", ["Strawberries", "Whipped cream", "Eggs", "Vanilla"], "1299"],
].map(([title, description, ingredients, price], i) => ({
  id: String(i), slug: title.toLowerCase().replace(/[^a-z0-9]+/g, "-"), title, description, ingredients,
  price, currency: "INR", is_available: i !== 3, is_featured: i < 3, images: [], cover_url: null,
}));

const demo = {
  bakery: { name: "Maison Cacao", tagline: "Royal cakes, baked with love", email: "hello@example.com", phone: "+91 98765 43210",
    whatsapp_number: "919876543210", address: "12 Rose Lane, Nashik, Maharashtra", logo_url: null,
    social_links: { instagram: "https://instagram.com", facebook: "https://facebook.com" } },
  content: { hero_title: "Cakes crafted like little celebrations", hero_subtitle: "Small-batch, made to order and finished by hand in our home kitchen.",
    hero_cta_label: "Explore our cakes", about_title: "A little story, a lot of butter",
    about_body: "What began as weekend baking for family has grown into a boutique bakery.\n\nEvery cake is made from scratch with real butter, fine chocolate and fresh seasonal ingredients, because celebrations deserve nothing less.",
    announcement: "Now taking orders for the festive season ✨", footer_note: "Baked fresh. Made with love.", hero_image_url: "" },
};

export const api = {
  bakery: () => (DEMO ? Promise.resolve(demo.bakery) : get("/api/public/bakery")),
  content: () => (DEMO ? Promise.resolve(demo.content) : get("/api/public/content")),
  cakes: (featured = false) =>
    DEMO ? Promise.resolve(featured ? demoCakes.filter((c) => c.is_featured) : demoCakes)
         : get(`/api/public/cakes${featured ? "?featured=true" : ""}`),
  cake: (slug) => {
    if (!DEMO) return get(`/api/public/cakes/${encodeURIComponent(slug)}`);
    const c = demoCakes.find((x) => x.slug === slug);
    return c ? Promise.resolve(c) : Promise.reject(Object.assign(new Error("Not found"), { status: 404 }));
  },
};

// Cloudinary delivers smaller, auto-format images when we ask for it.
export function img(url, width = 800) {
  if (!url || !url.includes("res.cloudinary.com") || !url.includes("/upload/")) return url;
  return url.replace("/upload/", `/upload/f_auto,q_auto,c_limit,w_${width}/`);
}

export function money(price, currency = "INR") {
  if (price === null || price === undefined || price === "") return null;
  try {
    return new Intl.NumberFormat("en-IN", { style: "currency", currency, maximumFractionDigits: 0 }).format(Number(price));
  } catch {
    return `${currency} ${price}`;
  }
}

export function whatsappLink(number, bakeryName, cakeTitle) {
  if (!number) return null;
  const text = cakeTitle
    ? `Hello ${bakeryName}! I'd love to enquire about the "${cakeTitle}" cake.`
    : `Hello ${bakeryName}! I'd like to enquire about a cake.`;
  return `https://wa.me/${number}?text=${encodeURIComponent(text)}`;
}
