import React, { useState, useEffect } from 'react';
import './App.css';
import {
  Moon,
  Sun,
  Award,
  CheckCircle2,
  Clock,
  BookOpen,
  Heart,
  Users,
  ShieldCheck,
  Send,
  Sparkles,
  Flame,
  Search,
  MessageSquare,
  BarChart3,
  Calendar,
  AlertCircle,
  Bell
} from 'lucide-react';

// Default Ihthisab Chart items based on FRD & Paper Chart
const INITIAL_ACTIVITIES = [
  {
    category: 'Farz Prayers',
    malayalamCategory: 'ഫർള് നിസ്കാരം',
    icon: '🕌',
    items: [
      { id: 'subhi', name: 'Subhi Prayer (with Jama\'ath)', ml: 'സുബ്ഹി നിസ്കാരം (ജമാഅത്തായി)', rating: 10 },
      { id: 'luhar', name: 'Luhar Prayer (with Jama\'ath)', ml: 'ളുഹ്ർ നിസ്കാരം (ജമാഅത്തായി)', rating: 10 },
      { id: 'asar', name: 'Asar Prayer (with Jama\'ath)', ml: 'അസ്വർ നിസ്കാരം (ജമാഅത്തായി)', rating: 10 },
      { id: 'maghrib', name: 'Maghrib Prayer (with Jama\'ath)', ml: 'മഗ്‌രിബ് നിസ്കാരം (ജമാഅത്തായി)', rating: 10 },
      { id: 'isha', name: 'Isha Prayer (with Jama\'ath)', ml: 'ഇശാഅ് നിസ്കാരം (ജമാഅത്തായി)', rating: 10 },
    ]
  },
  {
    category: 'Sunnah Prayers',
    malayalamCategory: 'സുന്നത്ത് നിസ്കാരം',
    icon: '✨',
    items: [
      { id: 'rawathib', name: 'Sunnah Rawathib Prayers', ml: 'റവാതിബ് സുന്നത്തുകൾ', rating: 5 },
      { id: 'vithr', name: 'Vithr Prayer', ml: 'വിത്ർ നിസ്കാരം', rating: 10 },
      { id: 'duha', name: 'Duha Prayer', ml: 'ളുഹാ നിസ്കാരം', rating: 5 },
      { id: 'tahajjud', name: 'Tahajjud / Qiyam al-Layl', ml: 'തഹജ്ജുദ് നിസ്കാരം', rating: 0 },
    ]
  },
  {
    category: 'Daily Routine & Character',
    malayalamCategory: 'ദിനചര്യ & സ്വഭാവം',
    icon: '📖',
    items: [
      { id: 'quran', name: 'Holy Quran Recitation (1 Ruku\'+)', ml: 'ഖുർആൻ പാരായണം തജ്‌വീദോടെ', rating: 10 },
      { id: 'parents', name: 'Respect & Obedience to Parents', ml: 'മാതാപിതാക്കളെ ആദരിക്കൽ & അനുസരിക്കൽ', rating: 10 },
      { id: 'helping', name: 'Helping with Household Chores', ml: 'വീട്ടുജോലികളിൽ സഹായിക്കൽ', rating: 5 },
      { id: 'routine', name: 'Early to Bed & Early to Rise', ml: 'സമയത്ത് ഉറങ്ങലും ഉണരലും', rating: 5 },
      { id: 'madrasa', name: 'Madrasa Lessons & Homework', ml: 'മദ്റസ പാഠങ്ങൾ കൃത്യമായി പഠിക്കൽ', rating: 10 },
    ]
  }
];

const INITIAL_STUDENTS = [
  { id: 1, name: 'Bilal Ahmed', roll: '101', batch: 'Batch 5-A', farz: '5/5', score: 135, status: 'Submitted', remark: 'MashaAllah! Very consistent in Subhi.' },
  { id: 2, name: 'Fathima Zahra', roll: '102', batch: 'Batch 5-A', farz: '5/5', score: 145, status: 'Submitted', remark: 'Excellent Quran recitation!' },
  { id: 3, name: 'Zayan Mohammed', roll: '103', batch: 'Batch 5-A', farz: '4/5', score: 98, status: 'Submitted', remark: 'Please focus on Asar in congregation.' },
  { id: 4, name: 'Maryam Noor', roll: '104', batch: 'Batch 5-A', farz: '5/5', score: 140, status: 'Submitted', remark: 'Top scorer this week!' },
  { id: 5, name: 'Omar Farooq', roll: '105', batch: 'Batch 5-A', farz: '3/5', score: 72, status: 'Pending', remark: 'Reminder sent to parent.' },
  { id: 6, name: 'Ayesha Siddiqa', roll: '106', batch: 'Batch 5-A', farz: '5/5', score: 130, status: 'Submitted', remark: 'MashaAllah, keep it up.' },
];

export default function App() {
  const [activePortal, setActivePortal] = useState('student'); // 'student', 'teacher', 'admin'
  const [activities, setActivities] = useState(INITIAL_ACTIVITIES);
  const [students, setStudents] = useState(INITIAL_STUDENTS);
  const [apiOnline, setApiOnline] = useState(false);
  const [toastMessage, setToastMessage] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStudentForRemark, setSelectedStudentForRemark] = useState(null);
  const [remarkInput, setRemarkInput] = useState('');

  // Check Backend API Health on boot
  useEffect(() => {
    fetch('http://localhost:4000/health')
      .then(res => res.json())
      .then(data => {
        if (data.status) {
          setApiOnline(true);
        }
      })
      .catch(() => {
        // Fallback gracefully to offline mode
        setApiOnline(false);
      });
  }, []);

  const showToast = (msg) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3500);
  };

  // Handle rating change
  const handleRatingChange = (categoryId, itemId, newRating) => {
    setActivities(prev =>
      prev.map(cat => {
        return {
          ...cat,
          items: cat.items.map(item => {
            if (item.id === itemId) {
              return { ...item, rating: newRating };
            }
            return item;
          })
        };
      })
    );
  };

  // Calculate scores
  const allItems = activities.flatMap(cat => cat.items);
  const totalScore = allItems.reduce((sum, item) => sum + (item.rating || 0), 0);
  const maxScore = allItems.length * 10;
  const scorePercentage = Math.round((totalScore / maxScore) * 100);

  // Submit today's Ihthisab
  const handleSaveIhthisab = async () => {
    try {
      const response = await fetch('http://localhost:4000/api/activity-logs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          studentId: 'std-101',
          date: new Date().toISOString().split('T')[0],
          score: totalScore,
          items: allItems.map(i => ({ id: i.id, rating: i.rating }))
        })
      });

      if (response.ok) {
        showToast('✨ AlhamduliLlah! Today\'s Ihthisab has been saved successfully.');
      } else {
        showToast('✨ Today\'s Ihthisab recorded locally (Score: ' + totalScore + ' pts)!');
      }
    } catch {
      showToast('✨ Today\'s Ihthisab recorded locally (Score: ' + totalScore + ' pts)!');
    }
  };

  // Submit Remark
  const handleSaveRemark = () => {
    if (!selectedStudentForRemark) return;
    setStudents(prev =>
      prev.map(s => s.id === selectedStudentForRemark.id ? { ...s, remark: remarkInput } : s)
    );
    showToast(`Remark updated for ${selectedStudentForRemark.name}`);
    setSelectedStudentForRemark(null);
    setRemarkInput('');
  };

  // Send Broadcast Notification
  const handleBroadcastNotification = () => {
    showToast('📢 Notification sent to all Parents & Students: "Time for Daily Ihthisab Marking!"');
  };

  return (
    <div className="app-container">
      {/* Toast Notification */}
      {toastMessage && (
        <div style={{
          position: 'fixed',
          bottom: '24px',
          right: '24px',
          background: '#064e3b',
          color: '#ffffff',
          padding: '14px 22px',
          borderRadius: '12px',
          boxShadow: '0 10px 25px rgba(0,0,0,0.2)',
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          zIndex: 9999,
          fontWeight: 600,
          border: '1px solid #34d399',
          animation: 'fadeIn 0.3s ease-out'
        }}>
          <Sparkles size={18} color="#fbbf24" />
          {toastMessage}
        </div>
      )}

      {/* Main Header */}
      <header className="main-header">
        <div className="brand-section">
          <div className="brand-crest">
            <span>أ</span>
          </div>
          <div>
            <h1 className="brand-title">
              ALIF
              <span style={{ fontWeight: 400, color: 'var(--primary-600)', fontSize: '1.05rem' }}>
                ONLINE MORAL SCHOOL
              </span>
            </h1>
            <div className="brand-subtitle">ഇഹ്തിസാബ് • Activity & Character Tracking</div>
          </div>
        </div>

        {/* Portal Switcher Tabs */}
        <div className="header-center">
          <button
            className={`portal-tab ${activePortal === 'student' ? 'active' : ''}`}
            onClick={() => setActivePortal('student')}
          >
            <BookOpen size={16} />
            Student Portal
          </button>
          <button
            className={`portal-tab ${activePortal === 'teacher' ? 'active' : ''}`}
            onClick={() => setActivePortal('teacher')}
          >
            <Users size={16} />
            Teacher Classroom
          </button>
          <button
            className={`portal-tab ${activePortal === 'admin' ? 'active' : ''}`}
            onClick={() => setActivePortal('admin')}
          >
            <ShieldCheck size={16} />
            Admin Hub
          </button>
        </div>

        {/* Right Status Badges */}
        <div className="header-right">
          <div className="api-pill" title={apiOnline ? 'Backend API connected' : 'Local mode active'}>
            <div className="api-dot" style={{ background: apiOnline ? '#10b981' : '#f59e0b' }} />
            {apiOnline ? 'API Connected' : 'Local Fallback'}
          </div>
          <div className="user-profile-badge">
            <div className="user-avatar">
              {activePortal === 'student' ? 'BA' : activePortal === 'teacher' ? 'TR' : 'AD'}
            </div>
            <div>
              <div className="user-name">
                {activePortal === 'student' ? 'Bilal Ahmed' : activePortal === 'teacher' ? 'Usthad Ismail' : 'Principal / Admin'}
              </div>
              <div className="user-role">
                {activePortal === 'student' ? 'Grade 5-A' : activePortal === 'teacher' ? 'Class Teacher' : 'Super Admin'}
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Hijri & Motivation Banner */}
      <div className="info-bar">
        <div className="info-bar-left">
          <div className="info-bar-date">
            <Calendar size={18} />
            <span>Today: {new Date().toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'short', year: 'numeric' })}</span>
          </div>
          <span className="info-bar-hijri">🌙 18 Jumada al-Awwal 1448 AH</span>
        </div>
        <div className="info-bar-quote">
          « إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا » — “Indeed, prayer is a timed obligation for the believers.”
        </div>
      </div>

      {/* ======================= PORTAL 1: STUDENT PORTAL ======================= */}
      {activePortal === 'student' && (
        <div className="student-grid animate-fade">
          {/* Left Column: Day Score & Badges */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div className="glass score-overview-card">
              <h2 style={{ fontSize: '1.1rem', color: 'var(--primary-900)' }}>Today's Ihthisab Score</h2>
              <div className="score-circle-wrapper">
                <div className="score-circle">
                  <div className="score-number">{totalScore}</div>
                  <div className="score-total">/ {maxScore} pts</div>
                </div>
                <div className="score-level-badge">
                  {scorePercentage >= 90 ? '🌟 Outstanding' : scorePercentage >= 70 ? '✨ Good Effort' : '🌱 Encouraged'}
                </div>
              </div>

              <div className="stat-pills">
                <div className="stat-pill">
                  <div className="stat-pill-label">
                    <Flame size={14} color="#f59e0b" />
                    Daily Streak
                  </div>
                  <div className="stat-pill-value">14 Days</div>
                </div>
                <div className="stat-pill">
                  <div className="stat-pill-label">
                    <Award size={14} color="#059669" />
                    Class Rank
                  </div>
                  <div className="stat-pill-value">#3 of 28</div>
                </div>
              </div>

              <button className="btn btn-primary" style={{ width: '100%' }} onClick={handleSaveIhthisab}>
                <CheckCircle2 size={18} />
                Save Today's Marks
              </button>
            </div>

            {/* Badges Earned */}
            <div className="glass badges-card">
              <div className="badges-card-title">
                <Award size={18} color="#d97706" />
                Earned Badges
              </div>
              <div className="badges-list">
                <div className="badge-item">
                  <div className="badge-icon">🌅</div>
                  <div className="badge-info">
                    <div className="badge-name">Fajr in Jama'ath Champion</div>
                    <div className="badge-desc">7 consecutive days of Subhi on time</div>
                  </div>
                </div>
                <div className="badge-item">
                  <div className="badge-icon">📖</div>
                  <div className="badge-info">
                    <div className="badge-name">Quran Companion</div>
                    <div className="badge-desc">Daily Quran recitation verified</div>
                  </div>
                </div>
                <div className="badge-item">
                  <div className="badge-icon">🤝</div>
                  <div className="badge-info">
                    <div className="badge-name">Kind & Dutiful</div>
                    <div className="badge-desc">Consistently obedient to parents</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Ihthisab Marking Chart */}
          <div className="ihthisab-sections">
            {/* Rating Legend Bar */}
            <div style={{
              background: '#ffffff',
              padding: '12px 20px',
              borderRadius: 'var(--radius-md)',
              border: '1px solid #e2e8f0',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: '12px'
            }}>
              <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-muted)' }}>
                Marking Legend:
              </span>
              <div style={{ display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
                <span className="badge badge-emerald">🟢 Excellent = 10 pts</span>
                <span className="badge badge-blue">🔵 Satisfactory = 5 pts</span>
                <span className="badge badge-gold">🟡 Needs Imp. = 2 pts</span>
                <span className="badge" style={{ background: '#ffe4e6', color: '#be123c', border: '1px solid #fecdd3' }}>🔴 Not Done = 0 pts</span>
              </div>
            </div>

            {/* Categories */}
            {activities.map(cat => (
              <div key={cat.category} className="ihthisab-category-card">
                <div className="category-header">
                  <div className="category-title-group">
                    <div className="category-icon-box">{cat.icon}</div>
                    <div>
                      <div className="category-title">{cat.category}</div>
                      <div className="category-arabic">{cat.malayalamCategory}</div>
                    </div>
                  </div>
                  <span className="badge badge-emerald">
                    {cat.items.reduce((s, i) => s + i.rating, 0)} pts earned
                  </span>
                </div>

                <div className="activities-list">
                  {cat.items.map(item => (
                    <div key={item.id} className="activity-row">
                      <div className="activity-name-box">
                        <span className="activity-name">{item.name}</span>
                        <span className="activity-malayalam">{item.ml}</span>
                      </div>

                      {/* Rating Pills */}
                      <div className="rating-pills-group">
                        <button
                          className={`rating-btn ${item.rating === 10 ? 'active-10' : ''}`}
                          onClick={() => handleRatingChange(cat.category, item.id, 10)}
                        >
                          10 • Exc.
                        </button>
                        <button
                          className={`rating-btn ${item.rating === 5 ? 'active-5' : ''}`}
                          onClick={() => handleRatingChange(cat.category, item.id, 5)}
                        >
                          5 • Sat.
                        </button>
                        <button
                          className={`rating-btn ${item.rating === 2 ? 'active-2' : ''}`}
                          onClick={() => handleRatingChange(cat.category, item.id, 2)}
                        >
                          2 • Needs Imp.
                        </button>
                        <button
                          className={`rating-btn ${item.rating === 0 ? 'active-0' : ''}`}
                          onClick={() => handleRatingChange(cat.category, item.id, 0)}
                        >
                          0 • No
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ======================= PORTAL 2: TEACHER PORTAL ======================= */}
      {activePortal === 'teacher' && (
        <div className="teacher-grid animate-fade">
          {/* Top Classroom Stats */}
          <div className="teacher-stats-bar">
            <div className="teacher-stat-card">
              <div className="teacher-stat-icon" style={{ background: '#ecfdf5', color: '#047857' }}>
                <Users size={24} />
              </div>
              <div>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Classroom</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 800 }}>Batch 5-A (28 Students)</div>
              </div>
            </div>

            <div className="teacher-stat-card">
              <div className="teacher-stat-icon" style={{ background: '#fef3c7', color: '#b45309' }}>
                <CheckCircle2 size={24} />
              </div>
              <div>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Submissions Today</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 800 }}>26 / 28 (93%)</div>
              </div>
            </div>

            <div className="teacher-stat-card">
              <div className="teacher-stat-icon" style={{ background: '#e0f2fe', color: '#0369a1' }}>
                <BarChart3 size={24} />
              </div>
              <div>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Class Average Score</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 800 }}>124 / 140 pts</div>
              </div>
            </div>
          </div>

          {/* Student Table */}
          <div className="table-card">
            <div className="table-header-controls">
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <h3 style={{ fontSize: '1.1rem' }}>Student Daily Monitoring</h3>
                <span className="badge badge-emerald">Live Records</span>
              </div>
              <div style={{ display: 'flex', gap: '12px' }}>
                <input
                  type="text"
                  placeholder="Search student name or roll..."
                  className="search-input"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
                <button className="btn btn-secondary" onClick={() => showToast('Syncing latest student records...')}>
                  Refresh
                </button>
              </div>
            </div>

            <table className="data-table">
              <thead>
                <tr>
                  <th>Roll</th>
                  <th>Student Name</th>
                  <th>Farz Prayers</th>
                  <th>Today's Score</th>
                  <th>Status</th>
                  <th>Teacher's Remark</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {students
                  .filter(s => s.name.toLowerCase().includes(searchQuery.toLowerCase()))
                  .map(s => (
                    <tr key={s.id}>
                      <td style={{ fontWeight: 700 }}>#{s.roll}</td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <div style={{
                            width: '32px',
                            height: '32px',
                            borderRadius: '50%',
                            background: '#e0e7ff',
                            color: '#4338ca',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: 700,
                            fontSize: '0.75rem'
                          }}>
                            {s.name.charAt(0)}
                          </div>
                          <span style={{ fontWeight: 600 }}>{s.name}</span>
                        </div>
                      </td>
                      <td>
                        <span className="badge badge-blue">🕌 {s.farz}</span>
                      </td>
                      <td>
                        <span style={{ fontWeight: 800, color: s.score >= 120 ? '#059669' : '#d97706' }}>
                          {s.score} pts
                        </span>
                      </td>
                      <td>
                        <span className={`badge ${s.status === 'Submitted' ? 'badge-emerald' : 'badge-gold'}`}>
                          {s.status}
                        </span>
                      </td>
                      <td style={{ fontStyle: 'italic', color: '#475569', maxWidth: '280px' }}>
                        {s.remark || 'No remark added yet'}
                      </td>
                      <td>
                        <button
                          className="btn btn-secondary"
                          style={{ padding: '6px 12px', fontSize: '0.8rem' }}
                          onClick={() => {
                            setSelectedStudentForRemark(s);
                            setRemarkInput(s.remark || '');
                          }}
                        >
                          <MessageSquare size={14} />
                          Add Remark
                        </button>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ======================= PORTAL 3: ADMIN HUB ======================= */}
      {activePortal === 'admin' && (
        <div className="admin-grid animate-fade">
          <div className="admin-banner">
            <div className="admin-banner-text">
              <h2>Alif Administration Management Hub</h2>
              <p>School-wide moral analytics, batch configurations, and notification broadcasting.</p>
            </div>
            <div style={{ display: 'flex', gap: '12px' }}>
              <button className="btn btn-gold" onClick={handleBroadcastNotification}>
                <Bell size={18} />
                Send Evening Marking Reminder
              </button>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '20px' }}>
            <div className="glass-card" style={{ padding: '24px' }}>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>Registered Students</div>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--primary-800)', margin: '8px 0' }}>342</div>
              <div style={{ fontSize: '0.8rem', color: '#059669', fontWeight: 600 }}>Across 12 Active Batches</div>
            </div>

            <div className="glass-card" style={{ padding: '24px' }}>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>Active Teachers</div>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--primary-800)', margin: '8px 0' }}>18</div>
              <div style={{ fontSize: '0.8rem', color: '#0369a1', fontWeight: 600 }}>100% On-boarded</div>
            </div>

            <div className="glass-card" style={{ padding: '24px' }}>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>Total Marks Logged</div>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--primary-800)', margin: '8px 0' }}>48,290</div>
              <div style={{ fontSize: '0.8rem', color: '#d97706', fontWeight: 600 }}>This Academic Term</div>
            </div>

            <div className="glass-card" style={{ padding: '24px' }}>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>Database & Services</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 800, color: '#059669', margin: '14px 0 6px 0' }}>
                🟢 Supabase & Node API
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Port 4000 • Operational</div>
            </div>
          </div>

          {/* Quick Config Card */}
          <div className="glass-card" style={{ padding: '24px' }}>
            <h3 style={{ marginBottom: '16px', fontSize: '1.15rem' }}>Active Ihthisab Categories & Weightage</h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '16px' }}>
              <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontWeight: 700, color: 'var(--primary-900)' }}>🕌 Farz Prayers (ഫർള്)</div>
                <div style={{ fontSize: '0.82rem', color: '#64748b', marginTop: '4px' }}>5 Activities • 10 pts each • Mandatory</div>
              </div>
              <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontWeight: 700, color: 'var(--primary-900)' }}>✨ Sunnah Prayers (സുന്നത്ത്)</div>
                <div style={{ fontSize: '0.82rem', color: '#64748b', marginTop: '4px' }}>4 Activities • 5-10 pts each • Optional</div>
              </div>
              <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontWeight: 700, color: 'var(--primary-900)' }}>📖 Character & Routine (സ്വഭാവം)</div>
                <div style={{ fontSize: '0.82rem', color: '#64748b', marginTop: '4px' }}>5 Activities • 5-10 pts each • Moral focus</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Remark Modal for Teachers */}
      {selectedStudentForRemark && (
        <div className="modal-backdrop" onClick={() => setSelectedStudentForRemark(null)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <h3 style={{ fontSize: '1.2rem', marginBottom: '8px' }}>
              Add Teacher Remark for {selectedStudentForRemark.name}
            </h3>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
              The student and parent will receive this message with their daily score card.
            </p>

            <div style={{ display: 'flex', gap: '8px', marginBottom: '14px', flexWrap: 'wrap' }}>
              <button
                className="btn btn-secondary"
                style={{ fontSize: '0.78rem', padding: '4px 10px' }}
                onClick={() => setRemarkInput('MashaAllah! Very consistent in Subhi and Jama\'ath.')}
              >
                + Consistent Subhi
              </button>
              <button
                className="btn btn-secondary"
                style={{ fontSize: '0.78rem', padding: '4px 10px' }}
                onClick={() => setRemarkInput('Excellent Tajweed recitation today. Keep it up!')}
              >
                + Great Tajweed
              </button>
              <button
                className="btn btn-secondary"
                style={{ fontSize: '0.78rem', padding: '4px 10px' }}
                onClick={() => setRemarkInput('Please ensure Asar prayer is prayed on time.')}
              >
                + Asar Reminder
              </button>
            </div>

            <textarea
              rows={4}
              value={remarkInput}
              onChange={e => setRemarkInput(e.target.value)}
              placeholder="Type your feedback or encouraging words here..."
              style={{
                width: '100%',
                padding: '12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontFamily: 'inherit',
                fontSize: '0.9rem',
                marginBottom: '18px',
                outline: 'none'
              }}
            />

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button className="btn btn-secondary" onClick={() => setSelectedStudentForRemark(null)}>
                Cancel
              </button>
              <button className="btn btn-primary" onClick={handleSaveRemark}>
                Save Remark
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
