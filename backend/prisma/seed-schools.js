/**
 * Seed 10 school records for demo/testing.
 * Run: node prisma/seed-schools.js
 * Or: npx prisma db seed (if configured)
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const SCHOOLS = [
  {
    name: 'Sunrise Public School',
    code: 'SPS001',
    subdomain: 'sunrise',
    board: 'CBSE',
    email: 'admin@sunriseschool.in',
    phone: '+919876543210',
    address: '12, Nehru Nagar, Sector 5',
    city: 'Ahmedabad',
    state: 'Gujarat',
    country: 'India',
    pinCode: '380015',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'STANDARD',
  },
  {
    name: 'Delhi Heritage Academy',
    code: 'DHA002',
    subdomain: 'delhiheritage',
    board: 'CBSE',
    email: 'principal@dha.edu.in',
    phone: '+919988776655',
    address: '47-B, Vasant Vihar',
    city: 'New Delhi',
    state: 'Delhi',
    country: 'India',
    pinCode: '110057',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'PREMIUM',
  },
  {
    name: 'Green Valley International',
    code: 'GVI003',
    subdomain: 'greenvalley',
    board: 'IB',
    email: 'info@greenvalley.school',
    phone: '+919123456789',
    address: 'Plot 88, MIDC Road',
    city: 'Pune',
    state: 'Maharashtra',
    country: 'India',
    pinCode: '411038',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'PREMIUM',
  },
  {
    name: 'Chennai Central School',
    code: 'CCS004',
    subdomain: 'chennaicentral',
    board: 'STATE_BOARD',
    email: 'admin@chennaicentral.in',
    phone: '+919876543211',
    address: '45, Anna Nagar East',
    city: 'Chennai',
    state: 'Tamil Nadu',
    country: 'India',
    pinCode: '600102',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'BASIC',
  },
  {
    name: 'Bangalore International Academy',
    code: 'BIA005',
    subdomain: 'bangaloreintl',
    board: 'ICSE',
    email: 'contact@bia.edu.in',
    phone: '+919876543212',
    address: '78, Koramangala 5th Block',
    city: 'Bangalore',
    state: 'Karnataka',
    country: 'India',
    pinCode: '560095',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'STANDARD',
  },
  {
    name: 'Kolkata Modern School',
    code: 'KMS006',
    subdomain: 'kolkatamodern',
    board: 'CBSE',
    email: 'info@kolkatamodern.in',
    phone: '+919876543213',
    address: '23, Park Street',
    city: 'Kolkata',
    state: 'West Bengal',
    country: 'India',
    pinCode: '700016',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'BASIC',
  },
  {
    name: 'Hyderabad Scholars Academy',
    code: 'HSA007',
    subdomain: 'hyderabadscholars',
    board: 'CBSE',
    email: 'admin@hsa.edu.in',
    phone: '+919876543214',
    address: '12, Banjara Hills',
    city: 'Hyderabad',
    state: 'Telangana',
    country: 'India',
    pinCode: '500034',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'STANDARD',
  },
  {
    name: 'Jaipur Royal Academy',
    code: 'JRA008',
    subdomain: 'jaipurroyal',
    board: 'CBSE',
    email: 'principal@jra.in',
    phone: '+919876543215',
    address: '56, C-Scheme',
    city: 'Jaipur',
    state: 'Rajasthan',
    country: 'India',
    pinCode: '302001',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'BASIC',
  },
  {
    name: 'Lucknow Progressive School',
    code: 'LPS009',
    subdomain: 'lucknowprogressive',
    board: 'ICSE',
    email: 'info@lps.edu.in',
    phone: '+919876543216',
    address: '34, Gomti Nagar',
    city: 'Lucknow',
    state: 'Uttar Pradesh',
    country: 'India',
    pinCode: '226010',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'STANDARD',
  },
  {
    name: 'Mumbai Metropolitan School',
    code: 'MMS010',
    subdomain: 'mumbaimetro',
    board: 'CBSE',
    email: 'admin@mms.in',
    phone: '+919876543217',
    address: '89, Bandra West',
    city: 'Mumbai',
    state: 'Maharashtra',
    country: 'India',
    pinCode: '400050',
    timezone: 'Asia/Kolkata',
    subscriptionPlan: 'PREMIUM',
  },
];

async function main() {
  console.log('Seeding 10 school records...\n');

  const now = new Date();
  const endDate = new Date(now);
  endDate.setFullYear(endDate.getFullYear() + 1);

  for (const school of SCHOOLS) {
    const existing = await prisma.school.findUnique({
      where: { code: school.code },
    });

    if (existing) {
      console.log(`  Skipped (exists): ${school.name} [${school.code}]`);
      continue;
    }

    await prisma.school.create({
      data: {
        name: school.name,
        code: school.code,
        subdomain: school.subdomain,
        board: school.board,
        email: school.email,
        phone: school.phone,
        address: school.address,
        city: school.city,
        state: school.state,
        country: school.country,
        pinCode: school.pinCode,
        timezone: school.timezone,
        status: 'ACTIVE',
        subscriptionPlan: school.subscriptionPlan,
        subscriptionStart: now,
        subscriptionEnd: endDate,
      },
    });
    console.log(`  Created: ${school.name} [${school.code}]`);
  }

  const total = await prisma.school.count();
  console.log(`\n✅ Done. Total schools in database: ${total}`);
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
