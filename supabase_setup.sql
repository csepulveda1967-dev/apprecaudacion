-- =====================================================================
-- ESQUEMA DE BASE DE DATOS EN SUPABASE PARA SISTEMA DE INVENTARIOS
-- =====================================================================

-- 1. Tabla de Productos (Maestro)
CREATE TABLE IF NOT EXISTS public.productos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo TEXT UNIQUE NOT NULL,
    nombre TEXT NOT NULL,
    area TEXT NOT NULL DEFAULT 'BAR', -- 'BAR' o 'COCINA'
    departamento TEXT DEFAULT 'BARRA',
    udm TEXT NOT NULL DEFAULT 'BOT', -- 'BOT', 'LTS', 'UNID', 'KG'
    stock_actual NUMERIC(10, 2) NOT NULL DEFAULT 0,
    stock_minimo NUMERIC(10, 2) NOT NULL DEFAULT 0,
    costo_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0,
    ubicacion TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Tabla de Movimientos Kardex (Auditoría en tiempo real)
CREATE TABLE IF NOT EXISTS public.movimientos_kardex (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha_hora TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    tipo TEXT NOT NULL, -- 'CIERRE DIARIO', 'INGRESO', 'MERMA', 'RECEPCIÓN', 'SOLICITUD LIBRE'
    producto_id UUID REFERENCES public.productos(id) ON DELETE CASCADE,
    codigo_producto TEXT,
    nombre_producto TEXT,
    cantidad NUMERIC(10, 2) NOT NULL,
    detalle TEXT,
    usuario_email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Tabla de Pedidos y Reposición a Bodega Central
CREATE TABLE IF NOT EXISTS public.pedidos_bodega (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id UUID REFERENCES public.productos(id) ON DELETE CASCADE,
    nombre_producto TEXT NOT NULL,
    cantidad_pedida NUMERIC(10, 2) NOT NULL,
    cantidad_recibida NUMERIC(10, 2),
    tipo TEXT NOT NULL DEFAULT 'Sugerido Mínimo', -- 'Sugerido Mínimo' o 'Libre / Evento'
    motivo TEXT,
    estado TEXT NOT NULL DEFAULT 'Pendiente', -- 'Pendiente', 'Recibido', 'Rechazado'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Seguridad a nivel de filas (Row Level Security - RLS)
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimientos_kardex ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_bodega ENABLE ROW LEVEL SECURITY;

-- Política de lectura general para usuarios autenticados
CREATE POLICY "Permitir lectura a usuarios autenticados" 
ON public.productos FOR SELECT 
TO authenticated 
USING (true);

-- Política para que el personal pueda registrar movimientos
CREATE POLICY "Permitir insercion de movimientos" 
ON public.movimientos_kardex FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- Política para pedidos de bodega
CREATE POLICY "Permitir gestion de pedidos" 
ON public.pedidos_bodega FOR ALL 
TO authenticated 
USING (true);
