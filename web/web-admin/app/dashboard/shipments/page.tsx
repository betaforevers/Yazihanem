'use client';

import { useState, useEffect } from 'react';
import { api } from '@/lib/api/client';

interface Shipment {
  id: string;
  tracking_number: string;
  customer: string;
  destination: string;
  departure_date: string;
  estimated_arrival: string;
  status: 'preparing' | 'in_transit' | 'customs' | 'delivered' | 'delayed';
  carrier: string;
  weight: number;
  temperature: number;
  created_at: string;
}

export default function ShipmentsPage() {
  const [shipments, setShipments] = useState<Shipment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [showModal, setShowModal] = useState(false);
  const [editingShipment, setEditingShipment] = useState<Shipment | null>(null);
  const [formData, setFormData] = useState({
    tracking_number: '',
    customer: '',
    destination: '',
    departure_date: '',
    estimated_arrival: '',
    status: 'preparing' as 'preparing' | 'in_transit' | 'customs' | 'delivered' | 'delayed',
    carrier: '',
    weight: 0,
    temperature: 0,
  });

  const fetchShipments = async () => {
    try {
      setLoading(true);
      const response = await api.listShipments();
      setShipments(response.items || []);
    } catch (error) {
      console.error('Error fetching shipments:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchShipments();
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'preparing':
        return 'bg-blue-100 text-blue-800';
      case 'in_transit':
        return 'bg-purple-100 text-purple-800';
      case 'customs':
        return 'bg-yellow-100 text-yellow-800';
      case 'delivered':
        return 'bg-green-100 text-green-800';
      case 'delayed':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'preparing':
        return 'Hazırlanıyor';
      case 'in_transit':
        return 'Yolda';
      case 'customs':
        return 'Gümrükte';
      case 'delivered':
        return 'Teslim Edildi';
      case 'delayed':
        return 'Gecikme';
      default:
        return status;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'preparing':
        return (
          <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
          </svg>
        );
      case 'in_transit':
        return (
          <svg className="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        );
      case 'customs':
        return (
          <svg className="w-5 h-5 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        );
      case 'delivered':
        return (
          <svg className="w-5 h-5 text-green-600" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
        );
      case 'delayed':
        return (
          <svg className="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
      default:
        return null;
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('tr-TR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  };

  const handleOpenModal = (shipment?: Shipment) => {
    if (shipment) {
      setEditingShipment(shipment);
      setFormData({
        tracking_number: shipment.tracking_number,
        customer: shipment.customer,
        destination: shipment.destination,
        departure_date: shipment.departure_date.slice(0, 16),
        estimated_arrival: shipment.estimated_arrival.slice(0, 16),
        status: shipment.status,
        carrier: shipment.carrier,
        weight: shipment.weight,
        temperature: shipment.temperature,
      });
    } else {
      setEditingShipment(null);
      setFormData({
        tracking_number: '',
        customer: '',
        destination: '',
        departure_date: '',
        estimated_arrival: '',
        status: 'preparing',
        carrier: '',
        weight: 0,
        temperature: 0,
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingShipment(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const submitData = {
        ...formData,
        departure_date: new Date(formData.departure_date).toISOString(),
        estimated_arrival: new Date(formData.estimated_arrival).toISOString(),
      };

      if (editingShipment) {
        await api.updateShipment(editingShipment.id, submitData);
      } else {
        await api.createShipment(submitData);
      }
      handleCloseModal();
      fetchShipments();
    } catch (error) {
      console.error('Error saving shipment:', error);
      alert('Kayıt sırasında hata oluştu');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Bu kaydı silmek istediğinizden emin misiniz?')) return;
    try {
      await api.deleteShipment(id);
      fetchShipments();
    } catch (error) {
      console.error('Error deleting shipment:', error);
      alert('Silme sırasında hata oluştu');
    }
  };

  const filteredShipments = filterStatus === 'all'
    ? shipments
    : shipments.filter(s => s.status === filterStatus);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Nakliye Takibi</h1>
          <p className="text-slate-600 mt-1">Sevkiyatları gerçek zamanlı takip edin</p>
        </div>
        <button
          onClick={() => handleOpenModal()}
          className="px-4 py-2 bg-cyan-600 text-white rounded-lg hover:bg-cyan-700 transition-colors"
        >
          <svg className="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Yeni Kayıt Ekle
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6">
        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-blue-100 rounded-lg">
              {getStatusIcon('preparing')}
            </div>
            <div>
              <p className="text-sm text-slate-600">Hazırlanıyor</p>
              <p className="text-2xl font-bold text-slate-900">{shipments.filter(s => s.status === 'preparing').length}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-purple-100 rounded-lg">
              {getStatusIcon('in_transit')}
            </div>
            <div>
              <p className="text-sm text-slate-600">Yolda</p>
              <p className="text-2xl font-bold text-slate-900">{shipments.filter(s => s.status === 'in_transit').length}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-yellow-100 rounded-lg">
              {getStatusIcon('customs')}
            </div>
            <div>
              <p className="text-sm text-slate-600">Gümrükte</p>
              <p className="text-2xl font-bold text-slate-900">{shipments.filter(s => s.status === 'customs').length}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-green-100 rounded-lg">
              {getStatusIcon('delivered')}
            </div>
            <div>
              <p className="text-sm text-slate-600">Teslim</p>
              <p className="text-2xl font-bold text-slate-900">{shipments.filter(s => s.status === 'delivered').length}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-red-100 rounded-lg">
              {getStatusIcon('delayed')}
            </div>
            <div>
              <p className="text-sm text-slate-600">Gecikme</p>
              <p className="text-2xl font-bold text-slate-900">{shipments.filter(s => s.status === 'delayed').length}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm p-4">
        <div className="flex gap-4 items-center">
          <label className="text-sm font-medium text-slate-700">Durum:</label>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
          >
            <option value="all">Tümü</option>
            <option value="preparing">Hazırlanıyor</option>
            <option value="in_transit">Yolda</option>
            <option value="customs">Gümrükte</option>
            <option value="delivered">Teslim Edildi</option>
            <option value="delayed">Gecikme</option>
          </select>
        </div>
      </div>

      {/* Shipments Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Takip No</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Müşteri</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Hedef</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Kargo Firması</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Ağırlık</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Kalkış</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Tahmini Varış</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Durum</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">İşlemler</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-slate-200">
              {loading ? (
                <tr>
                  <td colSpan={9} className="px-6 py-4 text-center text-slate-500">Yükleniyor...</td>
                </tr>
              ) : filteredShipments.length === 0 ? (
                <tr>
                  <td colSpan={9} className="px-6 py-4 text-center text-slate-500">Sevkiyat bulunamadı</td>
                </tr>
              ) : (
                filteredShipments.map((shipment) => (
                  <tr key={shipment.id} className="hover:bg-slate-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-mono font-medium text-cyan-600">{shipment.tracking_number}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-slate-900">{shipment.customer}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-600">{shipment.destination}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-600">{shipment.carrier}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-900">{shipment.weight} kg</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-600">{formatDate(shipment.departure_date)}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-600">{formatDate(shipment.estimated_arrival)}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusColor(shipment.status)}`}>
                        {getStatusText(shipment.status)}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button
                        onClick={() => handleOpenModal(shipment)}
                        className="text-cyan-600 hover:text-cyan-900 mr-4"
                      >
                        Düzenle
                      </button>
                      <button
                        onClick={() => handleDelete(shipment.id)}
                        className="text-red-600 hover:text-red-900"
                      >
                        Sil
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-8 max-w-md w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-2xl font-bold text-slate-900 mb-6">
              {editingShipment ? 'Kayıt Düzenle' : 'Yeni Kayıt Ekle'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Takip Numarası</label>
                <input
                  type="text"
                  required
                  value={formData.tracking_number}
                  onChange={(e) => setFormData({ ...formData, tracking_number: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Müşteri</label>
                <input
                  type="text"
                  required
                  value={formData.customer}
                  onChange={(e) => setFormData({ ...formData, customer: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Hedef</label>
                <input
                  type="text"
                  required
                  value={formData.destination}
                  onChange={(e) => setFormData({ ...formData, destination: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Kargo Firması</label>
                <input
                  type="text"
                  required
                  value={formData.carrier}
                  onChange={(e) => setFormData({ ...formData, carrier: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Ağırlık (kg)</label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.weight}
                    onChange={(e) => setFormData({ ...formData, weight: parseFloat(e.target.value) })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Sıcaklık (°C)</label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.temperature}
                    onChange={(e) => setFormData({ ...formData, temperature: parseFloat(e.target.value) })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Kalkış Tarihi</label>
                <input
                  type="datetime-local"
                  required
                  value={formData.departure_date}
                  onChange={(e) => setFormData({ ...formData, departure_date: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Tahmini Varış</label>
                <input
                  type="datetime-local"
                  required
                  value={formData.estimated_arrival}
                  onChange={(e) => setFormData({ ...formData, estimated_arrival: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Durum</label>
                <select
                  required
                  value={formData.status}
                  onChange={(e) => setFormData({ ...formData, status: e.target.value as 'preparing' | 'in_transit' | 'customs' | 'delivered' | 'delayed' })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
                >
                  <option value="preparing">Hazırlanıyor</option>
                  <option value="in_transit">Yolda</option>
                  <option value="customs">Gümrükte</option>
                  <option value="delivered">Teslim Edildi</option>
                  <option value="delayed">Gecikme</option>
                </select>
              </div>
              <div className="flex gap-4 mt-6">
                <button
                  type="submit"
                  className="flex-1 bg-cyan-600 text-white py-2 px-4 rounded-lg hover:bg-cyan-700 transition-colors"
                >
                  {editingShipment ? 'Güncelle' : 'Ekle'}
                </button>
                <button
                  type="button"
                  onClick={handleCloseModal}
                  className="flex-1 bg-slate-200 text-slate-700 py-2 px-4 rounded-lg hover:bg-slate-300 transition-colors"
                >
                  İptal
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
