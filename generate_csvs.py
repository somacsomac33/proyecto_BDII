import csv
import random
import os
from datetime import datetime, timedelta

# Configuración
NUM_RECORDS = 4000000

# Distribución de registros
DISTRIBUTION = {
    'tiendas': 50,
    'puesto_empleados': 20,
    'empleados': 50000,
    'proveedores': 200,
    'categoria_productos': 100,
    'productos': 50000,
    'clientes': 100000,
    'inventario': 1000000,
    'compra': 50000,
    'compra_producto': 300000,
    'venta': 800000,
    'detalles_venta': 1500000,
    'facturacion': 800000
}

class CleanDataGenerator:
    def __init__(self, output_dir="clean_csv_data"):
        self.output_dir = output_dir
        self.ids_cache = {}
        
        # Datos predefinidos SIN caracteres especiales
        self.nombres = ['Juan', 'Maria', 'Carlos', 'Ana', 'Luis', 'Laura', 'Miguel', 'Elena', 
                       'Jose', 'Isabel', 'Francisco', 'Carmen', 'Javier', 'Rosa', 'Antonio',
                       'Patricia', 'Pedro', 'Sandra', 'David', 'Andrea', 'Daniel', 'Marta',
                       'Jorge', 'Cristina', 'Manuel', 'Teresa', 'Pablo', 'Lucia', 'Angel',
                       'Raquel', 'Fernando', 'Silvia', 'Alberto', 'Paula', 'Sergio', 'Eva']
        
        self.apellidos = ['Garcia', 'Rodriguez', 'Gonzalez', 'Fernandez', 'Lopez', 'Martinez',
                         'Sanchez', 'Perez', 'Gomez', 'Martin', 'Jimenez', 'Ruiz', 'Hernandez',
                         'Diaz', 'Moreno', 'Munoz', 'Alvarez', 'Romero', 'Alonso', 'Gutierrez']
        
        self.ciudades = ['Ciudad de Mexico', 'Guadalajara', 'Monterrey', 'Puebla', 'Tijuana',
                        'Leon', 'Juarez', 'Zapopan', 'Nezahualcoyotl', 'Mexicali', 'Merida',
                        'Culiacan', 'Cancun', 'Queretaro', 'Aguascalientes', 'Hermosillo',
                        'Saltillo', 'Morelia', 'Toluca', 'Chihuahua']
        
        self.empresas = ['Tecnologia', 'Soluciones', 'Innovacion', 'Global', 'Servicios',
                        'Comercial', 'Industrial', 'Digital', 'Corporativo', 'Empresarial',
                        'Grupo', 'Holding', 'Internacional', 'Nacional', 'Regional']
        
        # Crear directorio de salida
        os.makedirs(output_dir, exist_ok=True)
    
    def clean_text(self, text):
        """Limpia el texto removiendo caracteres especiales"""
        if text is None:
            return ""
        # Permitir solo caracteres alfanuméricos básicos y espacios
        cleaned = ''.join(char for char in str(text) if char.isalnum() or char in ' .-_,@()')
        return cleaned.strip()
    
    def random_name(self):
        return f"{random.choice(self.nombres)} {random.choice(self.apellidos)}"
    
    def random_company(self):
        return f"{random.choice(self.empresas)} {random.choice(self.empresas)} SA de CV"
    
    def random_phone(self):
        return f"52{random.randint(100, 999)}{random.randint(100, 999)}{random.randint(1000, 9999)}"
    
    def random_email(self, name):
        domains = ['gmail.com', 'hotmail.com', 'yahoo.com', 'empresa.com', 'outlook.com']
        name_clean = name.lower().replace(' ', '.').replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u')
        name_clean = ''.join(char for char in name_clean if char.isalnum() or char in '.')
        return f"{name_clean}@{random.choice(domains)}"
    
    def random_date(self, start_year=2020, end_year=2024):
        year = random.randint(start_year, end_year)
        month = random.randint(1, 12)
        day = random.randint(1, 28)
        hour = random.randint(0, 23)
        minute = random.randint(0, 59)
        second = random.randint(0, 59)
        return datetime(year, month, day, hour, minute, second)
    
    def save_to_csv(self, filename, headers, data):
        """Guarda datos en archivo CSV"""
        filepath = os.path.join(self.output_dir, f"{filename}.csv")
        with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(headers)
            writer.writerows(data)
        print(f"✓ Guardados {len(data):,} registros en {filename}.csv")
    
    def generate_tiendas(self, num_records):
        """Genera datos para la tabla tiendas"""
        print("Generando tiendas...")
        data = []
        for i in range(num_records):
            ciudad = random.choice(self.ciudades)
            nombre = f"Tienda {ciudad} {i+1}"
            data.append([
                i + 1,  # id_tienda
                self.clean_text(nombre),
                self.clean_text(f"Calle {random.randint(1, 100)} Num {random.randint(100, 999)}"),
                self.random_phone(),
                self.clean_text(ciudad),
                self.random_date(),
                self.random_date()
            ])
        self.ids_cache['tiendas'] = [row[0] for row in data]
        return data
    
    def generate_puesto_empleados(self, num_records):
        """Genera datos para la tabla puesto_empleados"""
        print("Generando puestos de empleados...")
        puestos = [
            "Gerente General", "Subgerente", "Jefe de Departamento", 
            "Supervisor", "Vendedor Senior", "Vendedor", "Cajero",
            "Almacenista", "Auxiliar Administrativo", "Contador",
            "Recursos Humanos", "Marketing", "TI Soporte",
            "Limpieza", "Seguridad", "Logistica", "Compras",
            "Atencion a Clientes", "Telemarketing", "Analista"
        ]
        
        data = []
        for i in range(num_records):
            if i < len(puestos):
                puesto = puestos[i]
            else:
                puesto = f"Puesto Especializado {i+1}"
            
            data.append([
                i + 1,  # id_puesto
                self.clean_text(puesto),
                self.random_date(),
                self.random_date()
            ])
        self.ids_cache['puesto_empleados'] = [row[0] for row in data]
        return data
    
    def generate_empleados(self, num_records):
        """Genera datos para la tabla empleados"""
        print("Generando empleados...")
        tienda_ids = self.ids_cache.get('tiendas', [])
        puesto_ids = self.ids_cache.get('puesto_empleados', [])
        
        data = []
        for i in range(num_records):
            nombre_completo = self.random_name()
            partes_nombre = nombre_completo.split()
            
            data.append([
                i + 1,  # id_empleado
                self.clean_text(partes_nombre[0]),
                self.clean_text(partes_nombre[1]),
                self.clean_text(partes_nombre[1] if len(partes_nombre) > 2 else "Perez"),
                f"{random.randint(100000, 999999)}ABC",
                self.random_date(2015, 2023).date(),
                random.choice(tienda_ids) if tienda_ids and i > 0 else None,
                random.choice(puesto_ids) if puesto_ids and i > 0 else None,
                self.random_date(),
                self.random_date()
            ])
        self.ids_cache['empleados'] = [row[0] for row in data]
        return data
    
    def generate_proveedores(self, num_records):
        """Genera datos para la tabla proveedores"""
        print("Generando proveedores...")
        data = []
        for i in range(num_records):
            nombre_empresa = self.random_company()
            contacto = self.random_name()
            data.append([
                i + 1,  # id_proveedor
                self.clean_text(nombre_empresa),
                self.clean_text(contacto),
                self.random_email(contacto),
                self.random_phone(),
                self.random_date(),
                self.random_date()
            ])
        self.ids_cache['proveedores'] = [row[0] for row in data]
        return data
    
    def generate_categoria_productos(self, num_records):
        """Genera datos para la tabla categoria_productos"""
        print("Generando categorías de productos...")
        categorias = [
            "Electronicos", "Ropa", "Hogar", "Deportes", "Juguetes",
            "Libros", "Muebles", "Electrodomesticos", "Salud y Belleza",
            "Automotriz", "Herramientas", "Jardin", "Oficina", "Alimentos",
            "Bebidas", "Lacteos", "Carnes", "Frutas y Verduras", "Limpieza",
            "Mascotas", "Tecnologia", "Videojuegos", "Celulares", "Computadoras"
        ]
        
        data = []
        for i in range(num_records):
            if i < len(categorias):
                categoria = categorias[i]
                descripcion = f"Productos de {categoria}"
            else:
                categoria = f"Categoria {i+1}"
                descripcion = f"Descripcion para categoria {i+1}"
            
            data.append([
                i + 1,  # id_categoria
                self.clean_text(categoria),
                self.clean_text(descripcion),
                self.random_date(),
                self.random_date()
            ])
        self.ids_cache['categoria_productos'] = [row[0] for row in data]
        return data
    
    def generate_productos(self, num_records):
        """Genera datos para la tabla productos"""
        print("Generando productos...")
        categoria_ids = self.ids_cache.get('categoria_productos', [])
        proveedor_ids = self.ids_cache.get('proveedores', [])
        
        productos_base = [
            "Smartphone", "Laptop", "Tablet", "Televisor", "Refrigerador",
            "Lavadora", "Microondas", "Aire Acondicionado", "Camara", "Audifonos",
            "Zapatos", "Camisa", "Pantalon", "Vestido", "Chamarra",
            "Mesa", "Silla", "Sofa", "Cama", "Escritorio",
            "Balon", "Raqueta", "Bicicleta", "Tenis", "Pesas"
        ]
        
        data = []
        for i in range(num_records):
            if i < len(productos_base):
                producto = f"{productos_base[i]} Modelo {random.randint(2020, 2024)}"
            else:
                producto = f"Producto Premium {i+1}"
            
            precio_venta = round(random.uniform(10, 5000), 2)
            costo_compra = round(precio_venta * random.uniform(0.4, 0.8), 2)
            
            data.append([
                i + 1,  # id_producto
                f"SKU-{i:08d}",
                self.clean_text(producto),
                self.clean_text(f"Descripcion detallada del {producto}"),
                precio_venta,
                costo_compra,
                random.choice(categoria_ids) if categoria_ids and i > 0 else None,
                random.choice(proveedor_ids) if proveedor_ids and i > 0 else None,
                self.random_date(),
                self.random_date()
            ])
        self.ids_cache['productos'] = [row[0] for row in data]
        return data
    
    def generate_clientes(self, num_records):
        """Genera datos para la tabla clientes con RFCs únicos"""
        print("Generando clientes...")
        data = []
        used_rfcs = set()
        
        for i in range(num_records):
            nombre = self.random_name()
            
            # Generar RFC único (formato: 6 dígitos + 3 letras)
            max_attempts = 1000
            rfc_generated = False
            
            for attempt in range(max_attempts):
                digits = f"{random.randint(100000, 999999)}"
                letters = ''.join(random.choices('ABCDEFGHIJKLMNOPQRSTUVWXYZ', k=3))
                rfc = digits + letters
                
                if rfc not in used_rfcs:
                    used_rfcs.add(rfc)
                    rfc_generated = True
                    break
            
            # Si no se pudo generar único, añadir sufijo con ID
            if not rfc_generated:
                rfc = f"{random.randint(100000, 999999)}XYZ{i:06d}"
                used_rfcs.add(rfc)
            
            data.append([
                i + 1,  # id_cliente
                self.clean_text(nombre),
                rfc,
                self.random_email(nombre),
                self.random_phone(),
                self.random_date(),
                self.random_date()
            ])
            
            # Mostrar progreso cada 10000 registros
            if (i + 1) % 10000 == 0:
                print(f"  Progreso: {i + 1:,}/{num_records:,} - RFCs únicos: {len(used_rfcs)}")
        
        print(f"✅ RFCs únicos generados: {len(used_rfcs)}/{num_records}")
        self.ids_cache['clientes'] = [row[0] for row in data]
        return data
    
    def generate_inventario(self, num_records):
        """Genera datos para la tabla inventario"""
        print("Generando inventario...")
        tienda_ids = self.ids_cache.get('tiendas', [])
        producto_ids = self.ids_cache.get('productos', [])
        
        # Crear combinaciones únicas de tienda-producto
        combinations = set()
        data = []
        
        print(f"Generando {num_records} registros de inventario...")
        while len(data) < num_records:
            tienda_id = random.choice(tienda_ids)
            producto_id = random.choice(producto_ids)
            
            if (tienda_id, producto_id) not in combinations:
                combinations.add((tienda_id, producto_id))
                cantidad = random.randint(0, 1000)
                data.append([
                    tienda_id,
                    producto_id,
                    cantidad,
                    self.random_date(),
                    self.random_date()
                ])
                
                # Mostrar progreso cada 10000 registros
                if len(data) % 10000 == 0:
                    print(f"  Progreso: {len(data):,}/{num_records:,}")
        
        return data
    
    def generate_compra(self, num_records):
        """Genera datos para la tabla compra"""
        print("Generando compras...")
        proveedor_ids = self.ids_cache.get('proveedores', [])
        tienda_ids = self.ids_cache.get('tiendas', [])
        estados = ['pendiente', 'recibida', 'cancelada']
        
        data = []
        for i in range(num_records):
            fecha_compra = self.random_date(2022, 2024)
            estado = random.choices(estados, weights=[0.2, 0.7, 0.1])[0]
            recibida = (estado == 'recibida')
            aplicada = recibida and random.choice([True, False])
            
            data.append([
                i + 1,  # id_compra
                fecha_compra,
                random.choice(proveedor_ids) if proveedor_ids and i > 0 else None,
                random.choice(tienda_ids) if tienda_ids and i > 0 else None,
                0,  # total_compra
                estado,
                recibida,
                aplicada,
                fecha_compra + timedelta(days=random.randint(1, 15)) if recibida else None,
                self.random_date(),
                self.random_date()
            ])
        self.ids_cache['compra'] = [row[0] for row in data]
        return data
    
    def generate_compra_producto(self, num_records):
        """Genera datos para la tabla compra_producto SIN subtotal"""
        print("Generando líneas de compra...")
        compra_ids = self.ids_cache.get('compra', [])
        producto_ids = self.ids_cache.get('productos', [])
        
        data = []
        current_id = 1
        
        print(f"Generando {num_records} líneas de compra...")
        for compra_id in compra_ids:
            num_lineas = random.randint(1, 10)
            for orden in range(num_lineas):
                if current_id > num_records:
                    break
                
                producto_id = random.choice(producto_ids)
                cantidad = random.randint(1, 100)
                precio_unitario = round(random.uniform(5, 1000), 2)
                
                # SOLO 8 columnas (SIN subtotal - se genera automáticamente en la BD)
                data.append([
                    current_id,  # id_compra_producto
                    compra_id,
                    producto_id,
                    cantidad,
                    precio_unitario,
                    orden + 1,
                    self.random_date(),
                    self.random_date()
                ])
                current_id += 1
                
                # Mostrar progreso
                if current_id % 10000 == 0:
                    print(f"  Progreso: {current_id:,}/{num_records:,}")
            
            if current_id > num_records:
                break
        
        return data
    
    def generate_venta(self, num_records):
        """Genera datos para la tabla venta"""
        print("Generando ventas...")
        cliente_ids = self.ids_cache.get('clientes', [])
        empleado_ids = self.ids_cache.get('empleados', [])
        tienda_ids = self.ids_cache.get('tiendas', [])
        
        data = []
        for i in range(num_records):
            data.append([
                i + 1,  # id_venta
                self.random_date(2023, 2024),
                0,  # monto_total
                random.choice(cliente_ids) if cliente_ids and random.random() > 0.1 else None,
                random.choice(empleado_ids) if empleado_ids else None,
                random.choice(tienda_ids) if tienda_ids else None,
                self.random_date(),
                self.random_date()
            ])
        self.ids_cache['venta'] = [row[0] for row in data]
        return data
    
    def generate_detalles_venta(self, num_records):
        """Genera datos para la tabla detalles_venta SIN subtotal"""
        print("Generando detalles de venta...")
        venta_ids = self.ids_cache.get('venta', [])
        producto_ids = self.ids_cache.get('productos', [])
        
        data = []
        current_id = 1
        
        print(f"Generando {num_records} detalles de venta...")
        for venta_id in venta_ids:
            num_lineas = random.randint(1, 8)
            for orden in range(num_lineas):
                if current_id > num_records:
                    break
                
                producto_id = random.choice(producto_ids)
                cantidad = random.randint(1, 5)
                precio_unitario = round(random.uniform(10, 500), 2)
                
                # SOLO 8 columnas (SIN subtotal - se genera automáticamente en la BD)
                data.append([
                    current_id,  # id_detalle_venta
                    venta_id,
                    producto_id,
                    cantidad,
                    precio_unitario,
                    orden + 1,
                    self.random_date(),
                    self.random_date()
                ])
                current_id += 1
                
                # Mostrar progreso
                if current_id % 10000 == 0:
                    print(f"  Progreso: {current_id:,}/{num_records:,}")
            
            if current_id > num_records:
                break
        
        return data
    
    def generate_facturacion(self, num_records):
        """Genera datos para la tabla facturacion"""
        print("Generando facturación...")
        venta_ids = self.ids_cache.get('venta', [])
        metodos_pago = ['EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'TRANSFERENCIA']
        estados = ['emitida', 'cancelada', 'pendiente']
        
        data = []
        # Una factura por venta (hasta num_records)
        ventas_a_facturar = venta_ids[:num_records]
        
        for i, venta_id in enumerate(ventas_a_facturar):
            data.append([
                i + 1,  # id_factura
                venta_id,
                random.choice(['A', 'B', 'C']),
                str(random.randint(100000, 999999)),
                self.random_date(),
                round(random.uniform(100, 10000), 2),
                random.choice(metodos_pago),
                random.choices(estados, weights=[0.85, 0.05, 0.1])[0],
                f"/path/to/xml/factura_{venta_id}.xml",
                f"/path/to/pdf/factura_{venta_id}.pdf",
                self.random_date(),
                self.random_date()
            ])
        
        return data
    
    def generate_all_data(self):
        """Genera todos los datos y los guarda en CSV"""
        start_time = datetime.now()
        
        print("🚀 Iniciando generación de 4 millones de registros LIMPIOS...")
        print("📈 Distribución:")
        total_records = sum(DISTRIBUTION.values())
        for table, count in DISTRIBUTION.items():
            print(f"   {table}: {count:,} registros")
        print(f"   TOTAL: {total_records:,} registros\n")
        
        # Orden de generación según dependencias (HEADERS CORREGIDOS)
        generators = [
            ('tiendas', ['id_tienda', 'nombre', 'direccion', 'telefono', 'ciudad', 'created_at', 'updated_at'], self.generate_tiendas),
            ('puesto_empleados', ['id_puesto', 'nombre_puesto', 'created_at', 'updated_at'], self.generate_puesto_empleados),
            ('empleados', ['id_empleado', 'nombre', 'apellido_paterno', 'apellido_materno', 'rfc', 'fecha_contratacion', 'id_tienda', 'id_puesto', 'created_at', 'updated_at'], self.generate_empleados),
            ('proveedores', ['id_proveedor', 'nombre_empresa', 'contacto_nombre', 'contacto_email', 'contacto_telefono', 'created_at', 'updated_at'], self.generate_proveedores),
            ('categoria_productos', ['id_categoria', 'nombre_categoria', 'descripcion', 'created_at', 'updated_at'], self.generate_categoria_productos),
            ('productos', ['id_producto', 'sku', 'nombre_producto', 'descripcion', 'precio_venta', 'costo_compra', 'id_categoria', 'id_proveedor', 'created_at', 'updated_at'], self.generate_productos),
            ('clientes', ['id_cliente', 'nombre', 'rfc', 'email', 'telefono', 'created_at', 'updated_at'], self.generate_clientes),
            ('inventario', ['id_tienda', 'id_producto', 'cantidad', 'fecha_ultima_actualizacion', 'updated_at'], self.generate_inventario),
            ('compra', ['id_compra', 'fecha_compra', 'id_proveedor', 'id_tienda', 'total_compra', 'estado', 'recibida', 'aplicada', 'fecha_recepcion', 'created_at', 'updated_at'], self.generate_compra),
            # CORREGIDO: Sin subtotal
            ('compra_producto', ['id_compra_producto', 'id_compra', 'id_producto', 'cantidad', 'precio_unitario', 'orden', 'created_at', 'updated_at'], self.generate_compra_producto),
            ('venta', ['id_venta', 'fecha_hora', 'monto_total', 'id_cliente', 'id_empleado', 'id_tienda', 'created_at', 'updated_at'], self.generate_venta),
            # CORREGIDO: Sin subtotal
            ('detalles_venta', ['id_detalle_venta', 'id_venta', 'id_producto', 'cantidad', 'precio_unitario', 'orden', 'created_at', 'updated_at'], self.generate_detalles_venta),
            ('facturacion', ['id_factura', 'id_venta', 'serie', 'folio', 'fecha_emision', 'total', 'metodo_pago', 'estado', 'xml_path', 'pdf_path', 'created_at', 'updated_at'], self.generate_facturacion)
        ]
        
        total_generated = 0
        for table, headers, generator_func in generators:
            num_records = DISTRIBUTION.get(table, 0)
            if num_records > 0:
                print(f"\n--- Generando {table.upper()} ---")
                data = generator_func(num_records)
                self.save_to_csv(table, headers, data)
                total_generated += len(data)
        
        elapsed_time = (datetime.now() - start_time).total_seconds()
        print(f"\n🎉 Generación completada!")
        print(f"📊 Total de registros generados: {total_generated:,}")
        print(f"⏱️  Tiempo total: {elapsed_time:.2f} segundos")
        print(f"⚡ Velocidad: {total_generated/elapsed_time:.2f} registros/segundo")
        print(f"📁 Archivos guardados en: {os.path.abspath(self.output_dir)}")

if __name__ == "__main__":
    generator = CleanDataGenerator()
    generator.generate_all_data()