import { createContext, useContext, useEffect, useState } from "react";
import { api } from "./api.js";

const Ctx = createContext({ bakery: null, content: {}, loading: true, error: null });
export const useSite = () => useContext(Ctx);

export function SiteProvider({ children }) {
  const [state, set] = useState({ bakery: null, content: {}, loading: true, error: null });
  useEffect(() => {
    let live = true;
    Promise.all([api.bakery(), api.content()])
      .then(([bakery, content]) => live && set({ bakery, content, loading: false, error: null }))
      .catch((e) => live && set({ bakery: null, content: {}, loading: false, error: e.message }));
    return () => { live = false; };
  }, []);
  useEffect(() => {
    if (state.bakery?.name) document.title = `${state.bakery.name} · Handcrafted Cakes`;
  }, [state.bakery]);
  return <Ctx.Provider value={state}>{children}</Ctx.Provider>;
}

export function useFetch(fn, deps) {
  const [s, set] = useState({ data: null, loading: true, error: null });
  useEffect(() => {
    let live = true;
    set({ data: null, loading: true, error: null });
    fn().then((data) => live && set({ data, loading: false, error: null }))
        .catch((error) => live && set({ data: null, loading: false, error }));
    return () => { live = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
  return s;
}
