PGDMP     6                    z           Proyecto    13.6    13.6 K    #           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            $           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            %           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            &           1262    24608    Proyecto    DATABASE     g   CREATE DATABASE "Proyecto" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Spanish_Mexico.1252';
    DROP DATABASE "Proyecto";
                postgres    false            �            1255    32789    actualiza_monto_total_prod()    FUNCTION     @  CREATE FUNCTION public.actualiza_monto_total_prod() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
monto_finali integer;
monto_total_producto integer;
no_ventas integer;
precio_producto integer;
BEGIN
select ventas,precio into no_ventas,precio_producto from producto where producto.id_producto = new.id_producto; 
select monto_final into monto_finali from orden where orden.folio = new.folio; 

no_ventas = no_ventas + new.cantidad;
UPDATE producto SET ventas = no_ventas WHERE id_producto =  new.id_producto; --actualiza el numero de ventas, sumando el no que tenia mas la cantidad nueva

monto_total_producto = new.cantidad * precio_producto;
UPDATE orden_producto SET precio_total_por_producto = monto_total_producto WHERE id_producto =  new.id_producto and folio=new.folio;
-- actualiza el monto total de un producto y su cantidad

monto_finali = monto_finali + monto_total_producto;
UPDATE orden SET monto_final = monto_finali WHERE folio =  new.folio;
--se actualiza el monto total de la orden, sumando todos los montos por producto que pueda existir.
return new;
END;
$$;
 3   DROP FUNCTION public.actualiza_monto_total_prod();
       public          postgres    false            �            1255    24678    calcula_edad()    FUNCTION     +  CREATE FUNCTION public.calcula_edad() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
edadcal integer;
BEGIN
edadcal = (extract(year from now()) - extract(year from NEW.fecha_nacimiento))::integer;
UPDATE empleado SET edad = edadcal WHERE no_empleado = NEW.no_empleado;
RETURN NEW;
END;
$$;
 %   DROP FUNCTION public.calcula_edad();
       public          postgres    false            �            1255    32800    empleado_ordenes(text)    FUNCTION       CREATE FUNCTION public.empleado_ordenes(num_empleado text) RETURNS TABLE(folio_ord text, monto_orden integer)
    LANGUAGE plpgsql
    AS $$
DECLARE 
mesero char varying;
BEGIN
select empleado.horario into mesero from empleado where empleado.no_empleado = num_empleado ;
if mesero is null then 
	raise exception 'El empleado seleccionado NO es un mesero.';
else 
	RETURN QUERY
	select orden.folio,orden.monto_final from empleado 
	join orden on empleado.no_empleado = orden.no_empleado
	WHERE orden.fecha = now()::date;
END IF;

END;
$$;
 :   DROP FUNCTION public.empleado_ordenes(num_empleado text);
       public          postgres    false            �            1255    32817    factura(text)    FUNCTION       CREATE FUNCTION public.factura(folio_orden text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE 
fol text;
rfc_cliente char varying;
razon_cliente char varying;
fecha_orden date;
monto_orden integer;
registro Record;
productos CURSOR for select producto.nombre, producto.precio, cantidad,precio_total_por_producto
from orden_producto 
join producto on orden_producto.id_producto = producto.id_producto 
WHERE folio = folio_orden;
BEGIN

select folio,cliente.rfc,razon_social,orden.fecha,orden.monto_final
INTO fol,rfc_cliente,razon_cliente,fecha_orden,monto_orden from orden
JOIN cliente on rfc_cte = cliente.rfc WHERE folio = folio_orden;

if fol is not null then
		RAISE NOTICE '--------------------------------------------------------------------------------------------';
		RAISE NOTICE '------FOLIO: %--------------------------------FECHA: %-----------------------',fol,fecha_orden;
		RAISE NOTICE '------RFC EMISOR: CHE110527DQ3----------------------Nombre: Restaurante Los excentos--------';
		RAISE NOTICE '------REGIMEN FISCAL: ACTIVIDADES EMPRESARIALES-----EFECTO: INGRESO-------------------------';
		RAISE NOTICE '------USO DE CFDI: GASTOS EN GENERAL----------------FORMA DE PAGO:EFECTIVO------------------';
		RAISE NOTICE '--------------------------------------------------------------------------------------------';
		RAISE NOTICE '';
		RAISE NOTICE ' RFC RECEPTOR: %',rfc_cliente;
		RAISE NOTICE ' NOMBRE O RAZON SOCIAL: %',razon_cliente;
		RAISE NOTICE '';
		for registro in productos loop
			RAISE NOTICE 'PRODUCTO: %',registro.nombre;
		RAISE NOTICE '	   VALOR UNITARIO: $%   CANTIDAD: %   IMPORTE: $%',registro.precio,registro.cantidad,registro.precio_total_por_producto;
			RAISE NOTICE '';
		end loop;
		RAISE NOTICE '                                            --------------';
		RAISE NOTICE '                                              TOTAL:  $%',monto_orden;
else
	RAISE EXCEPTION 'La orden ingresada NO existe O NO se ha ingresado el RFC del cliente. ';
END IF;

RETURN 'Su factura se ha realizado correctamente';
END;
$_$;
 0   DROP FUNCTION public.factura(folio_orden text);
       public          postgres    false            �            1255    40994 f   ingresar_productos(character varying, integer, character varying, integer, character varying, integer)    FUNCTION     /  CREATE FUNCTION public.ingresar_productos(prod1 character varying, cant1 integer, prod2 character varying, cant2 integer, prod3 character varying, cant3 integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE 
id_1 integer ;
id_2 integer;
id_3 integer;
BEGIN
SELECT id_producto into id_1 FROM producto WHERE nombre = prod1;
SELECT id_producto into id_2 FROM producto WHERE nombre = prod2;
SELECT id_producto into id_3 FROM producto WHERE nombre = prod3;

if (prod1 = '0' and prod2 = '0' and prod3 = '0') then
	RAISE EXCEPTION 'No se ha ingresado ningun producto';
else
	INSERT INTO public.orden(no_empleado)VALUES ('EMP-001');
end if;
	

if prod1 != '0' then 
	INSERT INTO public.orden_producto(id_producto, folio, cantidad) VALUES (id_1, orden_actual(), cant1);
end if;


if prod2 != '0' then 
	INSERT INTO public.orden_producto(id_producto, folio, cantidad) VALUES (id_2, orden_actual(), cant2);
end if;


if prod3 != '0' then 
	INSERT INTO public.orden_producto(id_producto, folio, cantidad) VALUES (id_3, orden_actual(), cant3);
end if;
	

RETURN id_1;
END;
$$;
 �   DROP FUNCTION public.ingresar_productos(prod1 character varying, cant1 integer, prod2 character varying, cant2 integer, prod3 character varying, cant3 integer);
       public          postgres    false            �            1255    32819    no_ventas(date, date)    FUNCTION       CREATE FUNCTION public.no_ventas(fecha_ini date, fecha_fin date) RETURNS TABLE(no_ventas bigint, monto_total bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN QUERY
SELECT count(folio),sum(monto_final) from orden where fecha between fecha_ini and fecha_fin;

END;
$$;
 @   DROP FUNCTION public.no_ventas(fecha_ini date, fecha_fin date);
       public          postgres    false            �            1255    40980    orden_actual()    FUNCTION     �   CREATE FUNCTION public.orden_actual() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE fol text;
BEGIN
select folio into fol from orden order by folio desc
limit 1;

RETURN fol;
END;$$;
 %   DROP FUNCTION public.orden_actual();
       public          postgres    false            �            1255    24856    revisa_ingreso_productos()    FUNCTION     
  CREATE FUNCTION public.revisa_ingreso_productos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
	if new.ventas = 0 then
		    return new;
        else
		    raise exception 'No se puede ingresar manualmente el no de ventas del producto';		
	end if;
end; $$;
 1   DROP FUNCTION public.revisa_ingreso_productos();
       public          postgres    false            �            1255    24850     revisa_ingreso_productos_orden()    FUNCTION     z  CREATE FUNCTION public.revisa_ingreso_productos_orden() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
disponible bool;
nombre_prod char varying;
BEGIN
select disponibilidad,nombre into disponible,nombre_prod from producto where producto.id_producto = new.id_producto; 
if (disponible) then
	if new.precio_total_por_producto is not null then 
		if new.precio_total_por_producto = 0 then
			return new;
		else
			raise exception 'No se puede ingresar manualmente el monto total por el producto';
		end if;
	else
				return new;
	end if;
else 
	raise exception 'El producto % NO esta disponible',nombre_prod;
end if;
end; 
$$;
 7   DROP FUNCTION public.revisa_ingreso_productos_orden();
       public          postgres    false            �            1255    24834    revisa_orden()    FUNCTION     �  CREATE FUNCTION public.revisa_orden() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
horario_mesero char varying;
BEGIN
select horario into horario_mesero from empleado where empleado.no_empleado = new.no_empleado; 
if new.folio SIMILAR TO 'ORD-[0-9][0-9][0-9]' then 
        if new.monto_final = 0 then
		    if horario_mesero is null then
		        raise exception 'El empleado ingresado No es un mesero que pueda levantar ordenes';  
		    else
				return new;
            end if;
        else
            raise exception 'No se puede ingresar manualmente el monto total de la orden';
        end if;
else 
	raise exception 'El Numero de folio no tiene el formato correcto';
end if;
end; $$;
 %   DROP FUNCTION public.revisa_orden();
       public          postgres    false            �            1255    40986    telefonos(text)    FUNCTION     �  CREATE FUNCTION public.telefonos(emp text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE 
numero text;
pivote text = '';
registro Record;
telefonos CURSOR FOR select telefono from telefono
join empleado on empleado.no_empleado = telefono.no_empleado
WHERE telefono.no_empleado = emp order by telefono;

BEGIN
for registro in telefonos loop
		pivote = numero;
		--numero = concat(pivote,' ,', registro.telefono);
		numero = concat(registro.telefono,', ',pivote);
		end loop;
RETURN numero;
END;
$$;
 *   DROP FUNCTION public.telefonos(emp text);
       public          postgres    false            �            1255    24680    verificar_empleado()    FUNCTION     o  CREATE FUNCTION public.verificar_empleado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
if new.no_empleado SIMILAR TO 'EMP-[0-9][0-9][0-9]'   then
	if new.edad is not NULL then
			raise exception 'NO se puede ingresar la Edad Manualmente';	
	else	
		RETURN NEW;
	end if;
else 
	raise exception 'NO se puede ingresar el Numero de Empleado';
end if;

END;
$$;
 +   DROP FUNCTION public.verificar_empleado();
       public          postgres    false            �            1259    24736 	   categoria    TABLE     �   CREATE TABLE public.categoria (
    id_categoria integer NOT NULL,
    nombre_categoria character varying(8) NOT NULL,
    descripcion character varying(100) NOT NULL
);
    DROP TABLE public.categoria;
       public         heap    postgres    false            �            1259    24731    cliente    TABLE     �  CREATE TABLE public.cliente (
    rfc character varying(13) NOT NULL,
    razon_social character varying(55) NOT NULL,
    nombre character varying(50),
    ap_paterno character varying(30),
    ap_materno character varying(30),
    calle character varying(45),
    no_exterior character varying(10),
    colonia character varying(45),
    estado character varying(18),
    cp character varying(5),
    fecha_nacimiento date,
    email character varying(50)
);
    DROP TABLE public.cliente;
       public         heap    postgres    false            �            1259    24682    dependiente    TABLE       CREATE TABLE public.dependiente (
    curp character varying(18) NOT NULL,
    no_empleado text NOT NULL,
    nombre character varying(30) NOT NULL,
    ap_paterno character varying(25) NOT NULL,
    ap_materno character varying(25),
    parentesco character varying(14) NOT NULL
);
    DROP TABLE public.dependiente;
       public         heap    postgres    false            �            1259    24666    emp_seq    SEQUENCE     p   CREATE SEQUENCE public.emp_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CACHE 1;
    DROP SEQUENCE public.emp_seq;
       public          postgres    false            �            1259    24656    empleado    TABLE     �  CREATE TABLE public.empleado (
    no_empleado text DEFAULT ('EMP-'::text || lpad((nextval('public.emp_seq'::regclass))::text, 3, '0'::text)) NOT NULL,
    rfc character varying(13) NOT NULL,
    nombre character varying(20) NOT NULL,
    ap_paterno character varying(25) NOT NULL,
    ap_materno character varying(25),
    calle character varying(30) NOT NULL,
    no_exterior character varying(9) NOT NULL,
    colonia character varying(30) NOT NULL,
    estado character varying(20) NOT NULL,
    cp character varying(5) NOT NULL,
    fecha_nacimiento date NOT NULL,
    edad integer,
    sueldo integer NOT NULL,
    especialidad character varying(25),
    rol character varying(25),
    horario character varying(12),
    foto character varying(20) NOT NULL
);
    DROP TABLE public.empleado;
       public         heap    postgres    false    201            �            1259    24758 	   folio_seq    SEQUENCE     r   CREATE SEQUENCE public.folio_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CACHE 1;
     DROP SEQUENCE public.folio_seq;
       public          postgres    false            �            1259    24760    orden    TABLE     '  CREATE TABLE public.orden (
    folio text DEFAULT ('ORD-'::text || lpad((nextval('public.folio_seq'::regclass))::text, 3, '0'::text)) NOT NULL,
    fecha date DEFAULT (now())::date NOT NULL,
    monto_final integer DEFAULT 0,
    no_empleado text NOT NULL,
    rfc_cte character varying(13)
);
    DROP TABLE public.orden;
       public         heap    postgres    false    207            �            1259    24794    orden_producto    TABLE     �   CREATE TABLE public.orden_producto (
    id_producto integer NOT NULL,
    folio text NOT NULL,
    cantidad smallint NOT NULL,
    precio_total_por_producto integer DEFAULT 0
);
 "   DROP TABLE public.orden_producto;
       public         heap    postgres    false            �            1259    24743    producto_id_producto_seq    SEQUENCE     �   CREATE SEQUENCE public.producto_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.producto_id_producto_seq;
       public          postgres    false            �            1259    24745    producto    TABLE     �  CREATE TABLE public.producto (
    id_producto integer DEFAULT nextval('public.producto_id_producto_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion character varying(350) NOT NULL,
    receta character varying(350) NOT NULL,
    disponibilidad boolean NOT NULL,
    id_categoria integer NOT NULL,
    precio integer NOT NULL,
    ventas integer DEFAULT 0
);
    DROP TABLE public.producto;
       public         heap    postgres    false    205            �            1259    32805    platillo_mas_vendido    VIEW     �  CREATE VIEW public.platillo_mas_vendido AS
 SELECT p.id_producto,
    p.nombre,
    p.descripcion AS desc_plat,
    p.precio,
    p.ventas,
    p.disponibilidad,
    p.receta,
    c.nombre_categoria,
    c.descripcion AS desc_catego
   FROM (public.producto p
     JOIN public.categoria c ON ((c.id_categoria = p.id_categoria)))
  WHERE (c.id_categoria = 1)
  ORDER BY p.ventas DESC
 LIMIT 1;
 '   DROP VIEW public.platillo_mas_vendido;
       public          postgres    false    206    206    206    206    206    206    206    204    204    204    206            �            1259    32813    productos_no_disponibles    VIEW       CREATE VIEW public.productos_no_disponibles AS
 SELECT p.nombre,
    p.precio,
    p.disponibilidad,
    p.ventas,
    c.nombre_categoria
   FROM (public.producto p
     JOIN public.categoria c ON ((c.id_categoria = p.id_categoria)))
  WHERE (p.disponibilidad = false);
 +   DROP VIEW public.productos_no_disponibles;
       public          postgres    false    204    204    206    206    206    206    206            �            1259    24781    telefono    TABLE     m   CREATE TABLE public.telefono (
    telefono character varying(18) NOT NULL,
    no_empleado text NOT NULL
);
    DROP TABLE public.telefono;
       public         heap    postgres    false                      0    24736 	   categoria 
   TABLE DATA           P   COPY public.categoria (id_categoria, nombre_categoria, descripcion) FROM stdin;
    public          postgres    false    204   9~                 0    24731    cliente 
   TABLE DATA           �   COPY public.cliente (rfc, razon_social, nombre, ap_paterno, ap_materno, calle, no_exterior, colonia, estado, cp, fecha_nacimiento, email) FROM stdin;
    public          postgres    false    203   �~                 0    24682    dependiente 
   TABLE DATA           d   COPY public.dependiente (curp, no_empleado, nombre, ap_paterno, ap_materno, parentesco) FROM stdin;
    public          postgres    false    202   '�                 0    24656    empleado 
   TABLE DATA           �   COPY public.empleado (no_empleado, rfc, nombre, ap_paterno, ap_materno, calle, no_exterior, colonia, estado, cp, fecha_nacimiento, edad, sueldo, especialidad, rol, horario, foto) FROM stdin;
    public          postgres    false    200   ��                 0    24760    orden 
   TABLE DATA           P   COPY public.orden (folio, fecha, monto_final, no_empleado, rfc_cte) FROM stdin;
    public          postgres    false    208   �                  0    24794    orden_producto 
   TABLE DATA           a   COPY public.orden_producto (id_producto, folio, cantidad, precio_total_por_producto) FROM stdin;
    public          postgres    false    210   :�                 0    24745    producto 
   TABLE DATA           z   COPY public.producto (id_producto, nombre, descripcion, receta, disponibilidad, id_categoria, precio, ventas) FROM stdin;
    public          postgres    false    206   '�                 0    24781    telefono 
   TABLE DATA           9   COPY public.telefono (telefono, no_empleado) FROM stdin;
    public          postgres    false    209   �       '           0    0    emp_seq    SEQUENCE SET     5   SELECT pg_catalog.setval('public.emp_seq', 4, true);
          public          postgres    false    201            (           0    0 	   folio_seq    SEQUENCE SET     8   SELECT pg_catalog.setval('public.folio_seq', 57, true);
          public          postgres    false    207            )           0    0    producto_id_producto_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.producto_id_producto_seq', 9, true);
          public          postgres    false    205            h           2606    24663    empleado PK_No_Empleado 
   CONSTRAINT     `   ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT "PK_No_Empleado" PRIMARY KEY (no_empleado);
 C   ALTER TABLE ONLY public.empleado DROP CONSTRAINT "PK_No_Empleado";
       public            postgres    false    200            j           2606    24665    empleado RFC_UNIQUE 
   CONSTRAINT     O   ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT "RFC_UNIQUE" UNIQUE (rfc);
 ?   ALTER TABLE ONLY public.empleado DROP CONSTRAINT "RFC_UNIQUE";
       public            postgres    false    200            f           2606    40978    orden_producto cantidad_check    CHECK CONSTRAINT     g   ALTER TABLE public.orden_producto
    ADD CONSTRAINT cantidad_check CHECK ((cantidad >= 0)) NOT VALID;
 B   ALTER TABLE public.orden_producto DROP CONSTRAINT cantidad_check;
       public          postgres    false    210    210            s           2606    24740    categoria categoria_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);
 B   ALTER TABLE ONLY public.categoria DROP CONSTRAINT categoria_pkey;
       public            postgres    false    204            q           2606    24735    cliente cliente_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (rfc);
 >   ALTER TABLE ONLY public.cliente DROP CONSTRAINT cliente_pkey;
       public            postgres    false    203            _           2606    24829    cliente cp_check    CHECK CONSTRAINT     �   ALTER TABLE public.cliente
    ADD CONSTRAINT cp_check CHECK (((cp)::text ~ similar_to_escape('[0-9][0-9][0-9][0-9][0-9]'::text))) NOT VALID;
 5   ALTER TABLE public.cliente DROP CONSTRAINT cp_check;
       public          postgres    false    203    203            ]           2606    24830    empleado cp_check    CHECK CONSTRAINT     �   ALTER TABLE public.empleado
    ADD CONSTRAINT cp_check CHECK (((cp)::text ~ similar_to_escape('[0-9][0-9][0-9][0-9][0-9]'::text))) NOT VALID;
 6   ALTER TABLE public.empleado DROP CONSTRAINT cp_check;
       public          postgres    false    200    200            l           2606    24730    dependiente dependiente_PK 
   CONSTRAINT     i   ALTER TABLE ONLY public.dependiente
    ADD CONSTRAINT "dependiente_PK" PRIMARY KEY (curp, no_empleado);
 F   ALTER TABLE ONLY public.dependiente DROP CONSTRAINT "dependiente_PK";
       public            postgres    false    202    202            w           2606    24752    producto nombre_producto_uq 
   CONSTRAINT     X   ALTER TABLE ONLY public.producto
    ADD CONSTRAINT nombre_producto_uq UNIQUE (nombre);
 E   ALTER TABLE ONLY public.producto DROP CONSTRAINT nombre_producto_uq;
       public            postgres    false    206            u           2606    24742    categoria nombre_unique 
   CONSTRAINT     ^   ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT nombre_unique UNIQUE (nombre_categoria);
 A   ALTER TABLE ONLY public.categoria DROP CONSTRAINT nombre_unique;
       public            postgres    false    204            ~           2606    24768    orden orden_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.orden
    ADD CONSTRAINT orden_pkey PRIMARY KEY (folio);
 :   ALTER TABLE ONLY public.orden DROP CONSTRAINT orden_pkey;
       public            postgres    false    208            �           2606    24812     orden_producto orden_producto_PK 
   CONSTRAINT     p   ALTER TABLE ONLY public.orden_producto
    ADD CONSTRAINT "orden_producto_PK" PRIMARY KEY (id_producto, folio);
 L   ALTER TABLE ONLY public.orden_producto DROP CONSTRAINT "orden_producto_PK";
       public            postgres    false    210    210            y           2606    24750    producto producto_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id_producto);
 @   ALTER TABLE ONLY public.producto DROP CONSTRAINT producto_pkey;
       public            postgres    false    206            o           2606    24691    dependiente rfc_unique 
   CONSTRAINT     Q   ALTER TABLE ONLY public.dependiente
    ADD CONSTRAINT rfc_unique UNIQUE (curp);
 @   ALTER TABLE ONLY public.dependiente DROP CONSTRAINT rfc_unique;
       public            postgres    false    202            ^           2606    40979    empleado sueldo_check    CHECK CONSTRAINT     \   ALTER TABLE public.empleado
    ADD CONSTRAINT sueldo_check CHECK ((sueldo > 0)) NOT VALID;
 :   ALTER TABLE public.empleado DROP CONSTRAINT sueldo_check;
       public          postgres    false    200    200            �           2606    24788    telefono telefono_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.telefono
    ADD CONSTRAINT telefono_pkey PRIMARY KEY (telefono);
 @   ALTER TABLE ONLY public.telefono DROP CONSTRAINT telefono_pkey;
       public            postgres    false    209            z           1259    32965    fecha_index    INDEX     >   CREATE INDEX fecha_index ON public.orden USING btree (fecha);
    DROP INDEX public.fecha_index;
       public            postgres    false    208            m           1259    24728 '   fki_Empleado_Dependiente_no_empleado_FK    INDEX     h   CREATE INDEX "fki_Empleado_Dependiente_no_empleado_FK" ON public.dependiente USING btree (no_empleado);
 =   DROP INDEX public."fki_Empleado_Dependiente_no_empleado_FK";
       public            postgres    false    202            {           1259    24780    fki_orden_cliente_rfc_FK    INDEX     O   CREATE INDEX "fki_orden_cliente_rfc_FK" ON public.orden USING btree (rfc_cte);
 .   DROP INDEX public."fki_orden_cliente_rfc_FK";
       public            postgres    false    208            |           1259    24774 !   fki_orden_empleado_no_empleado_FK    INDEX     \   CREATE INDEX "fki_orden_empleado_no_empleado_FK" ON public.orden USING btree (no_empleado);
 7   DROP INDEX public."fki_orden_empleado_no_empleado_FK";
       public            postgres    false    208            �           1259    24810    fki_orden_orden_prod_folio_FK    INDEX     [   CREATE INDEX "fki_orden_orden_prod_folio_FK" ON public.orden_producto USING btree (folio);
 3   DROP INDEX public."fki_orden_orden_prod_folio_FK";
       public            postgres    false    210                       1259    24828    fki_telefono_emp_no_emp_FK    INDEX     X   CREATE INDEX "fki_telefono_emp_no_emp_FK" ON public.telefono USING btree (no_empleado);
 0   DROP INDEX public."fki_telefono_emp_no_emp_FK";
       public            postgres    false    209            �           2620    32790 )   orden_producto actualiza_monto_total_prod    TRIGGER     �   CREATE TRIGGER actualiza_monto_total_prod AFTER INSERT ON public.orden_producto FOR EACH ROW EXECUTE FUNCTION public.actualiza_monto_total_prod();
 B   DROP TRIGGER actualiza_monto_total_prod ON public.orden_producto;
       public          postgres    false    228    210            �           2620    24679    empleado calcula_edad    TRIGGER     q   CREATE TRIGGER calcula_edad AFTER INSERT ON public.empleado FOR EACH ROW EXECUTE FUNCTION public.calcula_edad();
 .   DROP TRIGGER calcula_edad ON public.empleado;
       public          postgres    false    213    200            �           2620    24861 !   producto revisa_ingreso_productos    TRIGGER     �   CREATE TRIGGER revisa_ingreso_productos BEFORE INSERT ON public.producto FOR EACH ROW EXECUTE FUNCTION public.revisa_ingreso_productos();
 :   DROP TRIGGER revisa_ingreso_productos ON public.producto;
       public          postgres    false    206    226            �           2620    24851 -   orden_producto revisa_ingreso_productos_orden    TRIGGER     �   CREATE TRIGGER revisa_ingreso_productos_orden BEFORE INSERT ON public.orden_producto FOR EACH ROW EXECUTE FUNCTION public.revisa_ingreso_productos_orden();
 F   DROP TRIGGER revisa_ingreso_productos_orden ON public.orden_producto;
       public          postgres    false    227    210            �           2620    24835    orden revisa_orden    TRIGGER     o   CREATE TRIGGER revisa_orden BEFORE INSERT ON public.orden FOR EACH ROW EXECUTE FUNCTION public.revisa_orden();
 +   DROP TRIGGER revisa_orden ON public.orden;
       public          postgres    false    208    230            �           2620    24681    empleado verificar    TRIGGER     u   CREATE TRIGGER verificar BEFORE INSERT ON public.empleado FOR EACH ROW EXECUTE FUNCTION public.verificar_empleado();
 +   DROP TRIGGER verificar ON public.empleado;
       public          postgres    false    200    214            �           2606    24723 /   dependiente Empleado_Dependiente_no_empleado_FK    FK CONSTRAINT     �   ALTER TABLE ONLY public.dependiente
    ADD CONSTRAINT "Empleado_Dependiente_no_empleado_FK" FOREIGN KEY (no_empleado) REFERENCES public.empleado(no_empleado) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 [   ALTER TABLE ONLY public.dependiente DROP CONSTRAINT "Empleado_Dependiente_no_empleado_FK";
       public          postgres    false    202    2920    200            �           2606    24813    orden orden_cliente_rfc_FK    FK CONSTRAINT     �   ALTER TABLE ONLY public.orden
    ADD CONSTRAINT "orden_cliente_rfc_FK" FOREIGN KEY (rfc_cte) REFERENCES public.cliente(rfc) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 F   ALTER TABLE ONLY public.orden DROP CONSTRAINT "orden_cliente_rfc_FK";
       public          postgres    false    2929    203    208            �           2606    24818 #   orden orden_empleado_no_empleado_FK    FK CONSTRAINT     �   ALTER TABLE ONLY public.orden
    ADD CONSTRAINT "orden_empleado_no_empleado_FK" FOREIGN KEY (no_empleado) REFERENCES public.empleado(no_empleado) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 O   ALTER TABLE ONLY public.orden DROP CONSTRAINT "orden_empleado_no_empleado_FK";
       public          postgres    false    208    2920    200            �           2606    24805 (   orden_producto orden_orden_prod_folio_FK    FK CONSTRAINT     �   ALTER TABLE ONLY public.orden_producto
    ADD CONSTRAINT "orden_orden_prod_folio_FK" FOREIGN KEY (folio) REFERENCES public.orden(folio) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 T   ALTER TABLE ONLY public.orden_producto DROP CONSTRAINT "orden_orden_prod_folio_FK";
       public          postgres    false    208    2942    210            �           2606    24753 +   producto producto_categoria_id_categoria_FK    FK CONSTRAINT     �   ALTER TABLE ONLY public.producto
    ADD CONSTRAINT "producto_categoria_id_categoria_FK" FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 W   ALTER TABLE ONLY public.producto DROP CONSTRAINT "producto_categoria_id_categoria_FK";
       public          postgres    false    206    2931    204            �           2606    24800 -   orden_producto producto_orden_prod_id_prod_FK    FK CONSTRAINT     �   ALTER TABLE ONLY public.orden_producto
    ADD CONSTRAINT "producto_orden_prod_id_prod_FK" FOREIGN KEY (id_producto) REFERENCES public.producto(id_producto) ON UPDATE CASCADE ON DELETE CASCADE;
 Y   ALTER TABLE ONLY public.orden_producto DROP CONSTRAINT "producto_orden_prod_id_prod_FK";
       public          postgres    false    2937    206    210            �           2606    24823    telefono telefono_emp_no_emp_FK    FK CONSTRAINT     �   ALTER TABLE ONLY public.telefono
    ADD CONSTRAINT "telefono_emp_no_emp_FK" FOREIGN KEY (no_empleado) REFERENCES public.empleado(no_empleado) ON UPDATE CASCADE ON DELETE RESTRICT NOT VALID;
 K   ALTER TABLE ONLY public.telefono DROP CONSTRAINT "telefono_emp_no_emp_FK";
       public          postgres    false    2920    200    209               �   x�]�]
�@��������x_�݈���l[���k��/�a�}�TE՚3%��Ba�-c�kbe�� w{a�_]�\ZH�:-��yݣ���$�<�,\%��X]�%�|�����^4�HG�i�RÛ�Z.]���DP         A  x�}��n�0��O���U&ޭa5@P���BŚ
����{���0��7[rn����ǈ] �|5��du�k� ޔ�	���npj9f��^V-ZʳD�4���FK���W@)��m�u��RK�����0P���=��?���"����ŉY�>~��:&�e�2��,�𗌣�8C�X�b}��S��zЧFC-�}���(d�A�^��8*��
U
�U7tPV��f�ђ,�P�z�˲}�al�|�g����("Ēe���Dh˓��ק�a��y�So�܍��H7�SJ�3��G	ڱ(D��JY����?�`�2���q�oΆ�         X   x���r60405��pqp�p��t��500�tK-�K�KI���/H��H-��Y�\��A!��.�p�i���9`�`� �1z\\\ ��         v  x�e��n*!��g�b_``����9m�֍�1�P�.�,����;�^����~�|��mA��l+	%����Ew��0	'{����C}Թ���{���܇�[`�B×�[o�9�n�TB`�wAD�j�"&�����h����ָ}8����0�������J��z�X�7ᬽ鐧�����!�3��pӹ�q����AM~	8N0�Ccw�l�[@vǀV��h���8�=�x�����1���6�o1}#*���^��>��6�O�L�a(�C�`�q>�L"�MD�D���<�e��L��y�K<�j��S�X��l&����f4�G*��͋��?~?]ΛV�9�����S���,����%           x����j1���wqяe;�%	��%�=�<B���&�Ue���|�4���|��v��(�D*�����0\ߦ�C�ϕ���V�}��W��V�Z��
V}��K���^���D�]�讧��	��飖.�%=���k�?�
��Z�c�������=9�8zvt�?t�C�?r�#�_� �
�޷!T�"�Q!�R1e��������	;w�Ν�s'���.j U�"�{#�P-b���5i��Z�y��`�ItX{3)�Dq	���K|}���̗�          �   x�]�;!@k�K2��ا�L���a��l���Y����@nP��&�9e�M�8� �f��l�@r�^��]6<eV`Ȩn�W�6je��B�K]�6�ÈEcXgX>�{�[�J����á���B�m�6E;���ݷ �8s)1��ó3��1e��sS�R�ͮѮ�<��2d�z'�_��h�����V��u��x�X��m�Ǝ�׿ϔ��B��         �  x��S�n�@��_� 8�d
H�*E� i�,�k��s$�H��"����Ҳ� �4�y����ݺC���{�9�b�$��\���s�9���:�^��#��2�`9�C�F�ә�\H�=[>}�V?��wϘ����P|�gE���$M$:����B��9M ��#:���5Q�c�lկG��w����v�k�}�V�#k�^SA�[P_����<2�\<+�e@�-����θ�tI��x�F��b�m�$F^ �AIw XےhW�m�FN�7���F6T����d�N9�%��9'���f~�e4�������c��Li��5,2��u�λ��w|Z��oK��n�ܛ�m�v��!D�<��z�ݔ�>/�z~|�`z����!�fE-?��n���ꐂ�3���D' �}��O�K>�E.j��ǜ�9>>���f(�ͅՊuC} 9U+�<���ـ�I�Ɉ���\ll��2\L#�Ϻ|��3;�d/��$j6��U�!�}	�����x�L�^�>(/lj�]��rv	˹���ʁ r�����������<��r��.�M+󁇜vN����@D�I��q��4wcu۸zW5.���w�7��]1�罩B��,8^X�:b9�ь�bQ�������K�j�Q�4K<��PnԞ@y����	sMO�������]]Ww7UU�L��t         c   x�M���0�3���q����
R�'$�L��ǹ�yɄ[cLP�pL��d3}��곽�	#�燊���H�*�>J|	V�N��R��&m     