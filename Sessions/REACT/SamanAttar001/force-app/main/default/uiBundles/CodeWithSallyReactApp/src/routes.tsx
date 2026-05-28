import type { RouteObject } from 'react-router';
import AppLayout from '@/appLayout';
import Home from './pages/Home';
import NotFound from './pages/NotFound';
import FoundingMembers from './pages/FoundingMembers';
import Contact from './pages/Contact';

export const routes: RouteObject[] = [
  {
    path: '/',
    element: <AppLayout />,
    children: [
      {
        index: true,
        element: <Home />,
        handle: { showInNavigation: true, label: 'Home' },
      },
      {
        path: '/founding-members',
        element: <FoundingMembers />,
        handle: { showInNavigation: true, label: 'Founding Members' },
      },
      {
        path: '/contact-us',
        element: <Contact />,
        handle: { showInNavigation: true, label: 'Contact Us' },
      },
      {
        path: '*',
        element: <NotFound />,
      },
    ],
  },
];
